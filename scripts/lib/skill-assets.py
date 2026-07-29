#!/usr/bin/env python3
"""Validate and publish set-aware Pi skills with exact ownership tracking."""

from __future__ import annotations

import json
import os
import re
import shutil
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


SETS = ("aad", "general")
SCHEMA_VERSION = 1
MANIFEST_NAME = ".pi-agent-setup-skills.json"
NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
GENERAL_COUPLING_PATTERN = re.compile(
    r"\bAAD\b|aad-|\.pi/aad|pi-subagents|task package|plan coordinator|"
    r"slice owner|owner hierarchy",
    re.IGNORECASE,
)
EXPECTED_INVENTORY = {
    "aad": {
        "aad-delegation",
        "aad-git-branching",
        "aad-plan-writing",
        "aad-reporting",
        "aad-task-package",
        "aad-workflow-feedback",
    },
    "general": {
        "backend-quality",
        "browser-chrome",
        "completion-verification",
        "devops-quality",
        "explanatory-html-pages",
        "frontend-quality",
        "modern-skill-revising",
        "visual-composition",
    },
}

# These names predate the ownership manifest. They are removed once, and only
# when their replacement set is selected. New removals are driven by manifest
# ownership rather than by extending this migration list.
LEGACY_NAMES = {
    "aad": (
        "aad-audit-convergence",
        "aad-codex-evidence",
        "aad-design-refinement",
        "aad-failure-classification",
        "aad-implementation-report",
        "aad-integration",
        "aad-review-handling",
        "aad-slicing-and-delegation",
        "aad-systematic-debugging",
        "aad-target-branch-preparation",
        "aad-verification",
        "aad-worktree-management",
        "agent-pipeline-feedback",
    ),
    "general": (
        "21st-magic-mcp",
        "acceptance-evidence-gate",
        "aad-quality-backend",
        "aad-quality-composition",
        "aad-quality-devops",
        "aad-quality-frontend",
        "aad-step-completion",
        "backend-api-data-quality",
        "browser-visual-report",
        "devops-runtime-readiness",
        "frontend-ui-quality",
        "modern-context-revising",
        "visual-composition-quality",
    ),
}


class SkillAssetsError(RuntimeError):
    """A source or target failed closed validation."""


@dataclass(frozen=True)
class Skill:
    set_name: str
    name: str
    source: Path
    source_relative: str


def selected_sets(set_name: str) -> tuple[str, ...]:
    if set_name == "all":
        return SETS
    if set_name in SETS:
        return (set_name,)
    raise SkillAssetsError(f"unknown skill set: {set_name}")


def validate_name(value: object, context: str) -> str:
    if not isinstance(value, str) or not NAME_PATTERN.fullmatch(value):
        raise SkillAssetsError(f"invalid skill name in {context}: {value!r}")
    return value


def scalar(raw: str, field: str, path: Path) -> str:
    value = raw.strip()
    if not value or value in {"|", ">"}:
        raise SkillAssetsError(f"missing or invalid {field} in {path}")
    if value.startswith('"'):
        try:
            decoded = json.loads(value)
        except json.JSONDecodeError as error:
            raise SkillAssetsError(f"invalid quoted {field} in {path}: {error}") from error
        if not isinstance(decoded, str) or not decoded.strip():
            raise SkillAssetsError(f"missing or invalid {field} in {path}")
        return decoded.strip()
    if value.startswith("'"):
        if re.fullmatch(r"'(?:[^']|'')*'", value) is None:
            raise SkillAssetsError(f"invalid quoted {field} in {path}")
        decoded = value[1:-1].replace("''", "'").strip()
        if not decoded:
            raise SkillAssetsError(f"missing or invalid {field} in {path}")
        return decoded
    if value[0] in "[{&*!|>@`" or re.fullmatch(
        r"(?i:null|true|false|~|[-+]?(?:\d+(?:\.\d*)?|\.\d+))", value
    ):
        raise SkillAssetsError(f"non-string {field} in {path}")
    return value


def parse_frontmatter(path: Path) -> tuple[str, str]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise SkillAssetsError(f"cannot read {path}: {error}") from error
    if not lines or lines[0].strip() != "---":
        raise SkillAssetsError(f"missing YAML frontmatter in {path}")
    try:
        end = next(index for index, line in enumerate(lines[1:], 1) if line.strip() == "---")
    except StopIteration as error:
        raise SkillAssetsError(f"unterminated YAML frontmatter in {path}") from error

    fields: dict[str, str] = {}
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[:1].isspace() or ":" not in line:
            continue
        key, raw = line.split(":", 1)
        key = key.strip()
        if key not in {"name", "description"}:
            continue
        if key in fields:
            raise SkillAssetsError(f"duplicate {key} in {path}")
        fields[key] = scalar(raw, key, path)

    if "name" not in fields:
        raise SkillAssetsError(f"missing or invalid name in {path}")
    if "description" not in fields:
        raise SkillAssetsError(f"missing or invalid description in {path}")
    return validate_name(fields["name"], str(path)), fields["description"]


def path_is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def reject_source_symlinks(root: Path) -> None:
    for current, directories, files in os.walk(root, topdown=True, followlinks=False):
        current_path = Path(current)
        kept_directories = []
        for directory in directories:
            candidate = current_path / directory
            if directory == ".git":
                continue
            if candidate.is_symlink():
                raise SkillAssetsError(f"symlink is not allowed in a skill source: {candidate}")
            kept_directories.append(directory)
        directories[:] = kept_directories
        for filename in files:
            candidate = current_path / filename
            if filename == ".git":
                continue
            if candidate.is_symlink():
                raise SkillAssetsError(f"symlink is not allowed in a skill source: {candidate}")


def discover(repo_root_value: str | Path) -> list[Skill]:
    repo_root = Path(repo_root_value).absolute()
    if repo_root.is_symlink() or not repo_root.is_dir():
        raise SkillAssetsError(f"invalid repository root: {repo_root}")
    repo_real = repo_root.resolve(strict=True)
    inventory: list[Skill] = []

    for set_name in SETS:
        source_root = repo_root / "skills" / set_name
        if source_root.is_symlink() or not source_root.is_dir():
            raise SkillAssetsError(f"missing or unsafe skill source root: {source_root}")
        source_real = source_root.resolve(strict=True)
        if not path_is_within(source_real, repo_real):
            raise SkillAssetsError(f"skill source root escapes repository: {source_root}")
        reject_source_symlinks(source_root)

        skill_files = sorted(
            path for path in source_root.rglob("SKILL.md") if ".git" not in path.parts
        )
        skill_directories = [path.parent for path in skill_files]
        for index, directory in enumerate(skill_directories):
            for other in skill_directories[index + 1 :]:
                if path_is_within(other, directory) or path_is_within(directory, other):
                    raise SkillAssetsError(
                        f"nested skill directories are unsafe: {directory} and {other}"
                    )

        for skill_file in skill_files:
            if skill_file.is_symlink() or not skill_file.is_file():
                raise SkillAssetsError(f"unsafe SKILL.md source: {skill_file}")
            source = skill_file.parent
            source_real = source.resolve(strict=True)
            if not path_is_within(source_real, source_root.resolve(strict=True)):
                raise SkillAssetsError(f"skill source escapes its set root: {source}")
            name, _description = parse_frontmatter(skill_file)
            if set_name == "general":
                content = skill_file.read_text(encoding="utf-8")
                match = GENERAL_COUPLING_PATTERN.search(content)
                if match is not None:
                    line = content[: match.start()].count("\n") + 1
                    raise SkillAssetsError(
                        f"general skill contains AAD workflow coupling at "
                        f"{skill_file}:{line}: {match.group(0)!r}"
                    )
            if source.name != name:
                raise SkillAssetsError(
                    f"skill leaf/frontmatter mismatch: {source.name!r} != {name!r} in {skill_file}"
                )
            inventory.append(
                Skill(
                    set_name=set_name,
                    name=name,
                    source=source,
                    source_relative=source.relative_to(repo_root).as_posix(),
                )
            )

    by_name: dict[str, Skill] = {}
    by_destination: dict[str, Skill] = {}
    for skill in inventory:
        previous = by_name.get(skill.name)
        if previous is not None:
            raise SkillAssetsError(
                f"duplicate runtime skill name {skill.name!r}: "
                f"{previous.source_relative} and {skill.source_relative}"
            )
        by_name[skill.name] = skill
        destination = skill.name
        previous = by_destination.get(destination)
        if previous is not None:
            raise SkillAssetsError(
                f"duplicate flattened skill destination {destination!r}: "
                f"{previous.source_relative} and {skill.source_relative}"
            )
        by_destination[destination] = skill
    return inventory


def validate_profile(repo_root: str | Path, set_name: str) -> list[Skill]:
    chosen = selected_sets(set_name)
    inventory = discover(repo_root)
    for chosen_set in chosen:
        actual = {skill.name for skill in inventory if skill.set_name == chosen_set}
        expected = EXPECTED_INVENTORY[chosen_set]
        if actual != expected:
            missing = ", ".join(sorted(expected - actual)) or "<none>"
            unexpected = ", ".join(sorted(actual - expected)) or "<none>"
            raise SkillAssetsError(
                f"unexpected {chosen_set} skill inventory; missing: {missing}; "
                f"unexpected: {unexpected}"
            )
    return inventory


def validate_absolute_target(agent_dir_value: str | Path) -> Path:
    raw = os.fspath(agent_dir_value)
    agent_dir = Path(raw)
    if not agent_dir.is_absolute() or ".." in agent_dir.parts or agent_dir == Path("/"):
        raise SkillAssetsError(f"unsafe Pi agent directory: {raw}")

    current = Path(agent_dir.anchor)
    for part in agent_dir.parts[1:]:
        current /= part
        if os.path.lexists(current):
            if current.is_symlink():
                raise SkillAssetsError(f"refusing symlinked target path: {current}")
            if current != agent_dir and not current.is_dir():
                raise SkillAssetsError(f"target parent is not a directory: {current}")
    if os.path.lexists(agent_dir) and not agent_dir.is_dir():
        raise SkillAssetsError(f"Pi agent target is not a directory: {agent_dir}")

    for managed in (agent_dir / "skills", agent_dir / MANIFEST_NAME):
        if os.path.lexists(managed) and managed.is_symlink():
            raise SkillAssetsError(f"refusing symlinked managed target: {managed}")
    if os.path.lexists(agent_dir / "skills") and not (agent_dir / "skills").is_dir():
        raise SkillAssetsError(f"skill target is not a directory: {agent_dir / 'skills'}")
    if os.path.lexists(agent_dir / MANIFEST_NAME) and not (agent_dir / MANIFEST_NAME).is_file():
        raise SkillAssetsError(f"ownership manifest is not a file: {agent_dir / MANIFEST_NAME}")
    return agent_dir


def empty_manifest() -> dict:
    return {
        "schemaVersion": SCHEMA_VERSION,
        "skillSets": {set_name: [] for set_name in SETS},
        "legacyCleanup": {set_name: 0 for set_name in SETS},
    }


def load_manifest(path: Path) -> dict:
    if not path.exists():
        return empty_manifest()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise SkillAssetsError(f"invalid ownership manifest {path}: {error}") from error
    if not isinstance(data, dict) or data.get("schemaVersion") != SCHEMA_VERSION:
        raise SkillAssetsError(f"unsupported ownership manifest schema in {path}")
    skill_sets = data.get("skillSets")
    if not isinstance(skill_sets, dict):
        raise SkillAssetsError(f"invalid skillSets in ownership manifest {path}")
    legacy = data.get("legacyCleanup", {})
    if not isinstance(legacy, dict):
        raise SkillAssetsError(f"invalid legacyCleanup in ownership manifest {path}")

    normalized = empty_manifest()
    seen: dict[str, str] = {}
    for set_name in SETS:
        names = skill_sets.get(set_name, [])
        if not isinstance(names, list):
            raise SkillAssetsError(f"invalid {set_name} ownership list in {path}")
        checked = []
        for item in names:
            name = validate_name(item, str(path))
            if name in checked:
                raise SkillAssetsError(f"duplicate owned skill {name!r} in {path}")
            if name in seen:
                raise SkillAssetsError(
                    f"skill {name!r} is owned by both {seen[name]} and {set_name} in {path}"
                )
            seen[name] = set_name
            checked.append(name)
        normalized["skillSets"][set_name] = checked
        marker = legacy.get(set_name, 0)
        if marker not in (0, 1):
            raise SkillAssetsError(f"invalid {set_name} legacy cleanup marker in {path}")
        normalized["legacyCleanup"][set_name] = marker
    return normalized


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def copy_skill(source: Path, target: Path) -> None:
    def ignore(_directory: str, names: list[str]) -> set[str]:
        return {".git"}.intersection(names)

    shutil.copytree(source, target, copy_function=shutil.copy2, ignore=ignore)


def write_manifest(path: Path, manifest: dict, workspace: Path) -> None:
    rendered = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    temporary = workspace / "manifest.json"
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(rendered)
            stream.flush()
            os.fsync(stream.fileno())
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        raise
    # The temporary file is created as 0600 and rename preserves that mode.
    # Keep this as the final fallible publication step so rollback never has to
    # reconcile a newly written manifest with restored skill directories.
    os.replace(temporary, path)


def install(repo_root: str | Path, agent_dir_value: str | Path, set_name: str) -> int:
    chosen_sets = selected_sets(set_name)
    inventory = discover(repo_root)
    selected = [skill for skill in inventory if skill.set_name in chosen_sets]
    agent_dir = validate_absolute_target(agent_dir_value)
    manifest_path = agent_dir / MANIFEST_NAME
    manifest = load_manifest(manifest_path)

    selected_by_name = {skill.name: skill for skill in selected}
    unselected_owned = {
        name: owner
        for owner in SETS
        if owner not in chosen_sets
        for name in manifest["skillSets"][owner]
    }
    collisions = sorted(set(selected_by_name).intersection(unselected_owned))
    if collisions:
        raise SkillAssetsError(
            "selected skills collide with ownership from an unselected set: " + ", ".join(collisions)
        )

    affected: set[str] = set(selected_by_name)
    for chosen in chosen_sets:
        affected.update(manifest["skillSets"][chosen])
        if manifest["legacyCleanup"][chosen] == 0:
            # A manifest entry is stronger ownership evidence than the
            # migration allowlist. Never let selected-set migration remove a
            # destination explicitly owned by an unselected set.
            affected.update(
                name for name in LEGACY_NAMES[chosen] if name not in unselected_owned
            )
    for name in affected:
        validate_name(name, "publication plan")
        destination = agent_dir / "skills" / name
        if os.path.lexists(destination) and destination.is_symlink():
            raise SkillAssetsError(f"refusing symlinked skill destination: {destination}")

    agent_dir.mkdir(parents=True, exist_ok=True)
    skills_dir = agent_dir / "skills"
    skills_dir.mkdir(mode=0o700, exist_ok=True)
    # Recheck after creation to narrow target-path races.
    validate_absolute_target(agent_dir)

    workspace = Path(tempfile.mkdtemp(prefix=".pi-agent-setup-skills-stage-", dir=agent_dir))
    staged = workspace / "staged"
    backups = workspace / "backups"
    staged.mkdir()
    backups.mkdir()
    published: list[str] = []
    backed_up: list[str] = []
    try:
        for name, skill in sorted(selected_by_name.items()):
            copy_skill(skill.source, staged / name)

        for name in sorted(affected):
            destination = skills_dir / name
            backup = backups / name
            if os.path.lexists(destination):
                if destination.is_symlink():
                    raise SkillAssetsError(f"refusing symlinked skill destination: {destination}")
                os.replace(destination, backup)
                backed_up.append(name)
            if name in selected_by_name:
                os.replace(staged / name, destination)
                published.append(name)

        updated = json.loads(json.dumps(manifest))
        for chosen in chosen_sets:
            updated["skillSets"][chosen] = sorted(
                skill.name for skill in selected if skill.set_name == chosen
            )
            updated["legacyCleanup"][chosen] = 1
        write_manifest(manifest_path, updated, workspace)
    except BaseException:
        for name in reversed(published):
            remove_path(skills_dir / name)
        for name in reversed(backed_up):
            backup = backups / name
            if os.path.lexists(backup):
                os.replace(backup, skills_dir / name)
        raise
    finally:
        shutil.rmtree(workspace, ignore_errors=True)
    return len(selected)


def inventory_payload(repo_root: str | Path, set_name: str) -> list[dict[str, str]]:
    chosen = selected_sets(set_name)
    return [
        {
            "name": skill.name,
            "set": skill.set_name,
            "source": skill.source_relative,
        }
        for skill in discover(repo_root)
        if skill.set_name in chosen
    ]


def main(argv: list[str]) -> None:
    command, args = (argv[1], argv[2:]) if len(argv) > 1 else ("", [])
    try:
        if command == "validate-source" and len(args) == 2:
            payload = inventory_payload(args[0], args[1])
            print(len(payload))
        elif command == "validate-profile" and len(args) == 2:
            chosen = selected_sets(args[1])
            inventory = validate_profile(args[0], args[1])
            print(sum(skill.set_name in chosen for skill in inventory))
        elif command == "validate-target" and len(args) == 1:
            validate_absolute_target(args[0])
        elif command == "inventory" and len(args) == 2:
            print(json.dumps(inventory_payload(args[0], args[1]), indent=2, sort_keys=True))
        elif command == "install" and len(args) == 3:
            print(install(args[0], args[1], args[2]))
        else:
            raise SkillAssetsError(
                "usage: skill-assets.py "
                "<validate-source REPO SET|validate-profile REPO SET|"
                "validate-target AGENT_DIR|inventory REPO SET|"
                "install REPO AGENT_DIR SET>"
            )
    except SkillAssetsError as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main(sys.argv)
