#!/usr/bin/env python3
"""Idempotent Pi setup JSON mutations and validation commands."""
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


def load(path: Path):
    return json.loads(path.read_text()) if path.exists() else {}


def backup(path: Path, suffix: str):
    if path.exists():
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        path.with_name(f"{path.name}.bak.{suffix}-{stamp}").write_text(path.read_text())


def write(path: Path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def merge_mcp(target: Path, source: Path, backup_suffix: str):
    data, config = load(target), load(source)
    data.setdefault("mcpServers", {}).update(config.get("mcpServers", {}))
    backup(target, backup_suffix)
    write(target, data)


def install_browser_chrome_mcp(target: Path, command: str):
    data = load(target)
    servers = data.setdefault("mcpServers", {})
    common_env = {"CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS": "1"}
    servers["browser-chrome-headed"] = {
        "command": command,
        "args": ["headed"],
        "lifecycle": "lazy",
        "env": common_env,
    }
    servers["browser-chrome-headless"] = {
        "command": command,
        "args": ["headless"],
        "lifecycle": "lazy",
        "idleTimeout": 1,
        "env": common_env,
    }
    backup(target, "browser-chrome")
    write(target, data)


def is_pi_codex_source(value):
    if not isinstance(value, str):
        return False
    normalized = value.rstrip("/")
    return (
        normalized in (
            "git:github.com/blockedby/pi-codex",
            "https://github.com/blockedby/pi-codex",
        )
        or normalized.endswith("/pi-codex")
        or normalized.endswith("/pi-codex.git")
    )


def update_settings(target: Path, codex: Path, desired_path: Path):
    data, desired = load(target), load(desired_path)
    backup(target, "update-local")
    relative_codex = os.path.relpath(codex.resolve(), target.parent.resolve())
    packages, found, result = data.setdefault("packages", []), False, []
    for item in packages:
        source = item.get("source") if isinstance(item, dict) else item
        if is_pi_codex_source(source):
            if not found:
                result.append({**item, "source": relative_codex} if isinstance(item, dict) else relative_codex)
                found = True
        else:
            result.append(item)
    if not found:
        result.insert(0, relative_codex)
    data["packages"] = result
    for key in ("defaultProvider", "defaultModel", "defaultThinkingLevel"):
        if key in desired:
            data[key] = desired[key]
    write(target, data)
    print(f"pi-codex package: {relative_codex}")


def verify_package_extensions(package_json: Path):
    extensions = load(package_json).get("pi", {}).get("extensions", [])
    if "./extensions/ready-notify.ts" not in extensions:
        raise SystemExit("package.json does not declare ./extensions/ready-notify.ts")
    print("Verified ready-notify extension declaration.")


def verify_subagents(config_path: Path):
    data = load(config_path)
    if data.get("scheduledRuns", {}).get("enabled") is not True:
        raise SystemExit("pi-subagents scheduledRuns.enabled is not true")
    control = data.get("control", {})
    if control.get("needsAttentionAfterMs") != 180000:
        raise SystemExit("pi-subagents needsAttentionAfterMs is not 180000")
    if control.get("notifyOn") != ["needs_attention"]:
        raise SystemExit("pi-subagents notifyOn must be ['needs_attention']")
    print("pi-subagents scheduled-runs and control config verified")



def main(argv):
    command = argv[1] if len(argv) > 1 else ""
    args = argv[2:]
    if command == "merge-mcp" and len(args) in (2, 3):
        merge_mcp(Path(args[0]), Path(args[1]), args[2] if len(args) == 3 else "pi-setup")
    elif command == "browser-chrome-mcp" and len(args) == 2:
        install_browser_chrome_mcp(Path(args[0]), args[1])
    elif command == "update-settings" and len(args) == 3:
        update_settings(Path(args[0]), Path(args[1]), Path(args[2]))
    elif command == "verify-package-extensions" and len(args) == 1:
        verify_package_extensions(Path(args[0]))
    elif command == "verify-subagents" and len(args) == 1:
        verify_subagents(Path(args[0]))
    else:
        raise SystemExit("usage: config-json.py <merge-mcp|browser-chrome-mcp|update-settings|verify-package-extensions|verify-subagents> ...")


if __name__ == "__main__":
    main(sys.argv)
