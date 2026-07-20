#!/usr/bin/env python3
"""Small, idempotent JSON mutations used by Pi setup deployment scripts."""
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
        "command": command, "args": ["headed"], "lifecycle": "lazy", "env": common_env,
    }
    servers["browser-chrome-headless"] = {
        "command": command, "args": ["headless"], "lifecycle": "lazy", "idleTimeout": 1, "env": common_env,
    }
    backup(target, "browser-chrome")
    write(target, data)


def is_pi_codex_source(value):
    if not isinstance(value, str):
        return False
    normalized = value.rstrip("/")
    return normalized in ("git:github.com/blockedby/pi-codex", "https://github.com/blockedby/pi-codex") or normalized.endswith("/pi-codex") or normalized.endswith("/pi-codex.git")


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


def main(argv):
    if argv[1:2] == ["merge-mcp"] and len(argv) in (4, 5):
        merge_mcp(Path(argv[2]), Path(argv[3]), argv[4] if len(argv) == 5 else "pi-setup")
    elif argv[1:2] == ["browser-chrome-mcp"] and len(argv) == 4:
        install_browser_chrome_mcp(Path(argv[2]), argv[3])
    elif argv[1:2] == ["update-settings"] and len(argv) == 5:
        update_settings(Path(argv[2]), Path(argv[3]), Path(argv[4]))
    else:
        raise SystemExit("usage: config-json.py merge-mcp <target> <source> [backup-label] | browser-chrome-mcp <target> <command> | update-settings <target> <codex> <desired>")


if __name__ == "__main__":
    main(sys.argv)
