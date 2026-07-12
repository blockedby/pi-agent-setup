#!/usr/bin/env python3
"""Deterministic Direct / Slice / Root and GPT-5.6 profile routing."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

BROWSER_MODES = {"none", "functional", "standard-ui", "full-visual"}
AUTHORIZATIONS = {"inspect", "change"}


class RoutingError(ValueError):
    """Raised when a routing descriptor or policy is invalid."""


def _default_config_path() -> Path:
    installed = Path.home() / ".pi" / "agent" / "aad-routing.json"
    if installed.is_file():
        return installed

    here = Path(__file__).resolve()
    repo_candidate = here.parents[3] / "settings" / "aad-routing.json"
    if repo_candidate.is_file():
        return repo_candidate

    raise RoutingError(
        "Routing config not found. Set --config or install "
        "~/.pi/agent/aad-routing.json."
    )


def _load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise RoutingError(f"File not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise RoutingError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RoutingError(f"Expected a JSON object in {path}")
    return value


def _read_descriptor(path: str | None) -> dict[str, Any]:
    if path:
        return _load_json(Path(path))
    try:
        value = json.load(sys.stdin)
    except json.JSONDecodeError as exc:
        raise RoutingError(f"Invalid descriptor JSON on stdin: {exc}") from exc
    if not isinstance(value, dict):
        raise RoutingError("Descriptor must be a JSON object")
    return value


def _bool(desc: dict[str, Any], key: str, default: bool = False) -> bool:
    value = desc.get(key, default)
    if not isinstance(value, bool):
        raise RoutingError(f"{key} must be boolean")
    return value


def _int(desc: dict[str, Any], key: str, default: int) -> int:
    value = desc.get(key, default)
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise RoutingError(f"{key} must be a non-negative integer")
    return value


def _profile(config: dict[str, Any], name: str) -> dict[str, str]:
    profiles = config.get("profiles")
    if not isinstance(profiles, dict) or not isinstance(profiles.get(name), dict):
        raise RoutingError(f"Missing profile: {name}")
    raw = profiles[name]
    model = raw.get("model")
    thinking = raw.get("thinking")
    if not isinstance(model, str) or not model:
        raise RoutingError(f"Profile {name} has no model")
    if not isinstance(thinking, str) or not thinking:
        raise RoutingError(f"Profile {name} has no thinking level")
    forbidden = set(config.get("forbiddenThinkingLevels", []))
    if thinking in forbidden:
        raise RoutingError(f"Profile {name} uses forbidden thinking level: {thinking}")
    return {
        "name": name,
        "model": model,
        "thinking": thinking,
        "runtimeModel": f"{model}:{thinking}",
    }


def route(desc: dict[str, Any], config: dict[str, Any]) -> dict[str, Any]:
    authorization = desc.get("authorization", "inspect")
    if authorization not in AUTHORIZATIONS:
        raise RoutingError(
            f"authorization must be one of {sorted(AUTHORIZATIONS)}"
        )

    browser_mode = desc.get("browserMode", "none")
    if browser_mode not in BROWSER_MODES:
        raise RoutingError(f"browserMode must be one of {sorted(BROWSER_MODES)}")

    risk_flags_raw = desc.get("riskFlags", [])
    if not isinstance(risk_flags_raw, list) or not all(
        isinstance(item, str) and item for item in risk_flags_raw
    ):
        raise RoutingError("riskFlags must be an array of non-empty strings")
    risk_flags = sorted(set(risk_flags_raw))

    direct_eligible = _bool(desc, "directEligible")
    mutation = _bool(desc, "mutation")
    ownership_boundaries = _int(desc, "ownershipBoundaries", 1)
    acceptance_stories = _int(desc, "acceptanceStories", 1)
    integration_required = _bool(desc, "integrationRequired")

    approval_flags = {
        "externalAction": _bool(desc, "externalAction"),
        "destructiveAction": _bool(desc, "destructiveAction"),
        "credentialOrSessionAccess": _bool(desc, "credentialOrSessionAccess"),
        "materialScopeExpansion": _bool(desc, "materialScopeExpansion"),
    }
    consequential_ambiguity = _bool(desc, "consequentialAmbiguity")

    root_required = (
        ownership_boundaries > 1
        or acceptance_stories > 1
        or integration_required
    )
    direct_allowed = (
        direct_eligible
        and not root_required
        and browser_mode == "none"
        and not consequential_ambiguity
        and not any(approval_flags.values())
    )

    if root_required:
        route_name = "root"
    elif direct_allowed:
        route_name = "direct"
    else:
        route_name = "slice"

    weights = config.get("deepScoreWeights", {})
    if not isinstance(weights, dict):
        raise RoutingError("deepScoreWeights must be an object")

    score = 0
    score_reasons: list[str] = []
    boolean_score_fields = (
        "contradictoryEvidence",
        "integrationRequired",
        "previousFailedAttempt",
        "novelArchitecture",
    )
    for key in boolean_score_fields:
        if _bool(desc, key):
            weight = int(weights.get(key, 0))
            score += weight
            if weight:
                score_reasons.append(f"{key}+{weight}")

    for flag in risk_flags:
        weight = int(weights.get(flag, 0))
        score += weight
        if weight:
            score_reasons.append(f"{flag}+{weight}")

    threshold = int(config.get("deepScoreThreshold", 2))
    if route_name == "root" or score >= threshold:
        owner_profile_name = "deep"
    elif route_name == "slice":
        owner_profile_name = "work"
    else:
        owner_profile_name = "deep"

    if any(approval_flags.values()):
        human_gate = "APPROVE"
    elif consequential_ambiguity:
        human_gate = "CONSULT"
    elif route_name in set(config.get("defaults", {}).get("informRoutes", [])):
        human_gate = "INFORM"
    else:
        human_gate = "NONE"

    full_risk_flags = set(config.get("fullRiskFlags", []))
    audit_required = route_name in set(
        config.get("defaults", {}).get("auditRoutes", ["slice", "root"])
    )
    full_risk = (
        route_name == "root"
        or integration_required
        or _bool(desc, "contradictoryEvidence")
        or bool(full_risk_flags.intersection(risk_flags))
    )

    support: list[dict[str, Any]] = []
    if _bool(desc, "discoveryNeeded"):
        support.append({
            "agent": "aad-explorer",
            "profile": _profile(config, "evidence"),
            "required": True,
            "reason": "bounded discovery requested",
        })
    if browser_mode != "none":
        support.append({
            "agent": "chrome-browser-agent",
            "profile": _profile(config, "work"),
            "required": True,
            "reason": f"browser mode {browser_mode} requires a separate context",
        })
    if _bool(desc, "separateImplementationNeeded"):
        implementation_profile = "deep" if score >= threshold else "work"
        support.append({
            "agent": "aad-implementer",
            "profile": _profile(config, implementation_profile),
            "required": True,
            "reason": "separate implementation context requested",
        })
    if audit_required:
        support.append({
            "agent": "aad-acceptance-auditor",
            "profile": _profile(config, "work"),
            "required": True,
            "mode": "full-risk" if full_risk else "compact",
            "reason": f"independent {route_name} boundary audit",
        })

    defaults = config.get("defaults", {})
    worktree_required = bool(
        mutation and defaults.get("worktreeForMutation", True)
    )

    if route_name == "direct":
        artifact_mode = "none"
    elif route_name == "slice":
        artifact_mode = "compact"
    else:
        artifact_mode = "root"

    return {
        "schemaVersion": config.get("schemaVersion", 1),
        "route": route_name,
        "authorization": authorization,
        "owner": (
            "terminal-main"
            if route_name == "direct"
            else "aad-slice-owner"
            if route_name == "slice"
            else "aad-root-owner"
        ),
        "ownerProfile": _profile(config, owner_profile_name),
        "deepScore": score,
        "deepScoreThreshold": threshold,
        "deepScoreReasons": score_reasons,
        "humanGate": human_gate,
        "worktreeRequired": worktree_required,
        "browserMode": browser_mode,
        "browserSeparateContext": bool(
            browser_mode != "none"
            and defaults.get("browserSeparateContext", True)
        ),
        "auditRequired": audit_required,
        "auditMode": "full-risk" if audit_required and full_risk else (
            "compact" if audit_required else "none"
        ),
        "artifactMode": artifact_mode,
        "artifactRoot": (
            None if artifact_mode == "none" else ".pi/aad/<task-id>/"
        ),
        "support": support,
        "approvalReasons": [
            key for key, enabled in approval_flags.items() if enabled
        ],
        "riskFlags": risk_flags,
    }


def _fixture(**overrides: Any) -> dict[str, Any]:
    value: dict[str, Any] = {
        "authorization": "change",
        "directEligible": False,
        "mutation": True,
        "ownershipBoundaries": 1,
        "acceptanceStories": 1,
        "integrationRequired": False,
        "browserMode": "none",
        "discoveryNeeded": False,
        "separateImplementationNeeded": False,
        "contradictoryEvidence": False,
        "previousFailedAttempt": False,
        "novelArchitecture": False,
        "consequentialAmbiguity": False,
        "externalAction": False,
        "destructiveAction": False,
        "credentialOrSessionAccess": False,
        "materialScopeExpansion": False,
        "riskFlags": [],
    }
    value.update(overrides)
    return value


def self_test(config: dict[str, Any]) -> None:
    cases = [
        (
            "direct read",
            _fixture(
                authorization="inspect",
                directEligible=True,
                mutation=False,
            ),
            {"route": "direct", "auditRequired": False, "humanGate": "NONE"},
        ),
        (
            "direct mutation",
            _fixture(directEligible=True),
            {"route": "direct", "worktreeRequired": True},
        ),
        (
            "ordinary slice",
            _fixture(),
            {
                "route": "slice",
                "ownerProfile.name": "work",
                "auditMode": "compact",
                "humanGate": "INFORM",
            },
        ),
        (
            "browser slice",
            _fixture(browserMode="standard-ui"),
            {
                "route": "slice",
                "browserSeparateContext": True,
                "auditRequired": True,
            },
        ),
        (
            "deep contradictory slice",
            _fixture(contradictoryEvidence=True),
            {"route": "slice", "ownerProfile.name": "deep"},
        ),
        (
            "root integration",
            _fixture(
                ownershipBoundaries=3,
                acceptanceStories=3,
                integrationRequired=True,
            ),
            {
                "route": "root",
                "ownerProfile.name": "deep",
                "auditMode": "full-risk",
            },
        ),
        (
            "approval gate",
            _fixture(externalAction=True),
            {"route": "slice", "humanGate": "APPROVE"},
        ),
    ]

    def get_path(value: dict[str, Any], path: str) -> Any:
        current: Any = value
        for part in path.split("."):
            current = current[part]
        return current

    for name, descriptor, expected in cases:
        decision = route(descriptor, config)
        for path, expected_value in expected.items():
            actual = get_path(decision, path)
            if actual != expected_value:
                raise AssertionError(
                    f"{name}: {path} expected {expected_value!r}, got {actual!r}"
                )
        runtime_model = decision["ownerProfile"]["runtimeModel"]
        if runtime_model.endswith(":xhigh") or runtime_model.endswith(":max"):
            raise AssertionError(f"{name}: forbidden runtime model {runtime_model}")

    print(f"routing self-test passed: {len(cases)} fixtures")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", help="routing config JSON path")
    parser.add_argument("--input", help="descriptor JSON path; default stdin")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()

    try:
        config_path = Path(args.config) if args.config else _default_config_path()
        config = _load_json(config_path)
        if args.self_test:
            self_test(config)
            return 0
        descriptor = _read_descriptor(args.input)
        decision = route(descriptor, config)
    except (RoutingError, AssertionError) as exc:
        print(f"routing error: {exc}", file=sys.stderr)
        return 2

    json.dump(
        decision,
        sys.stdout,
        indent=2 if args.pretty else None,
        sort_keys=True,
    )
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
