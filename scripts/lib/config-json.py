#!/usr/bin/env python3
"""Small JSON helpers used by the local setup script."""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


def load(path: Path) -> dict:
    return json.loads(path.read_text()) if path.exists() else {}


def save(path: Path, data: dict, backup_label: str | None = None) -> None:
    rendered = json.dumps(data, indent=2) + "\n"
    if path.exists() and path.read_text() == rendered:
        return
    if path.exists() and backup_label:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        backup = path.with_name(f"{path.name}.bak.{backup_label}-{stamp}")
        backup.write_text(path.read_text())
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(rendered)


def package_source(item):
    return item.get("source") if isinstance(item, dict) else item


def is_pi_codex(value) -> bool:
    if not isinstance(value, str):
        return False
    value = value.rstrip("/")
    return (
        value in {"git:github.com/blockedby/pi-codex", "https://github.com/blockedby/pi-codex"}
        or value.endswith("/pi-codex")
        or value.endswith("/pi-codex.git")
    )


def update_settings(target: Path, codex_dir: Path, desired_path: Path) -> None:
    current = load(target)
    desired = load(desired_path)
    local_codex = os.path.relpath(codex_dir.resolve(), target.parent.resolve())

    packages = [local_codex]
    seen = {local_codex}
    for item in current.get("packages", []) + desired.get("packages", []):
        source = package_source(item)
        if is_pi_codex(source) or source in seen:
            continue
        packages.append(item)
        if isinstance(source, str):
            seen.add(source)

    current["packages"] = packages
    for key in ("defaultProvider", "defaultModel", "defaultThinkingLevel"):
        if key in desired:
            current[key] = desired[key]
    save(target, current, "update-local")
    print(f"pi-codex package: {local_codex}")


def install_browser_mcp(target: Path, browser_command: str, control_command: str) -> None:
    data = load(target)
    servers = data.setdefault("mcpServers", {})
    servers["browser-chrome-control"] = {
        "command": control_command,
        "args": [],
        "lifecycle": "lazy",
    }
    common_env = {"CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS": "1"}
    servers["browser-chrome-headed"] = {
        "command": browser_command,
        "args": ["headed"],
        "lifecycle": "lazy",
        "env": common_env,
    }
    servers["browser-chrome-headless"] = {
        "command": browser_command,
        "args": ["headless"],
        "lifecycle": "lazy",
        "idleTimeout": 1,
        "env": common_env,
    }
    save(target, data, "browser-chrome")


def verify_package(package_json: Path) -> None:
    package = load(package_json)
    extensions = package.get("pi", {}).get("extensions", [])
    if "./extensions/ready-notify.ts" not in extensions:
        raise SystemExit("package.json does not declare ready-notify.ts")
    if package.get("type") != "module":
        raise SystemExit("package.json must use ESM for the OpenCode plugin")
    if package.get("main") != "./.opencode/plugins/pi-agent-setup.js":
        raise SystemExit("package.json does not declare the OpenCode plugin entrypoint")
    if package.get("scripts", {}).get("test:opencode") != "node scripts/test-opencode-adapter.mjs":
        raise SystemExit("package.json does not declare the OpenCode adapter test")


def verify_subagents(config_path: Path) -> None:
    data = load(config_path)
    if data.get("scheduledRuns", {}).get("enabled") is not True:
        raise SystemExit("pi-subagents scheduled runs are not enabled")
    control = data.get("control", {})
    if control.get("needsAttentionAfterMs") != 180000:
        raise SystemExit("unexpected pi-subagents attention timeout")
    if control.get("notifyOn") != ["needs_attention"]:
        raise SystemExit("unexpected pi-subagents notification policy")


def main(argv: list[str]) -> None:
    command, args = (argv[1], argv[2:]) if len(argv) > 1 else ("", [])
    if command == "update-settings" and len(args) == 3:
        update_settings(Path(args[0]), Path(args[1]), Path(args[2]))
    elif command == "browser-chrome-mcp" and len(args) == 3:
        install_browser_mcp(Path(args[0]), args[1], args[2])
    elif command == "verify-package" and len(args) == 1:
        verify_package(Path(args[0]))
    elif command == "verify-subagents" and len(args) == 1:
        verify_subagents(Path(args[0]))
    else:
        raise SystemExit(
            "usage: config-json.py "
            "<update-settings|browser-chrome-mcp|verify-package|verify-subagents> ..."
        )


if __name__ == "__main__":
    main(sys.argv)
