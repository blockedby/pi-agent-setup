#!/usr/bin/env python3
"""Tests for the standalone local setup JSON helper."""

import json
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent
TOOL = ROOT / "scripts/lib/config-json.py"


def run(*args: str) -> None:
    subprocess.run([sys.executable, str(TOOL), *map(str, args)], check=True)


def run_failure(*args: str) -> str:
    result = subprocess.run(
        [sys.executable, str(TOOL), *map(str, args)],
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0, f"expected failure for: {args}"
    return result.stderr


def read(path: Path):
    return json.loads(path.read_text())


with tempfile.TemporaryDirectory() as temporary:
    temp = Path(temporary)
    agent_dir = temp / "home/.pi/agent"
    agent_dir.mkdir(parents=True)
    settings = agent_dir / "settings.json"
    desired = temp / "desired.json"
    codex = temp / "repo/packages/pi-codex"
    codex.mkdir(parents=True)

    settings.write_text(json.dumps({"packages": ["npm:custom", "git:github.com/blockedby/pi-codex"], "keep": True}))
    desired.write_text(json.dumps({
        "defaultProvider": "openai-codex",
        "defaultModel": "test-model",
        "defaultThinkingLevel": "high",
        "packages": [
            "git:github.com/blockedby/pi-codex",
            "npm:pi-subagents",
            {"source": "npm:theme", "enabled": False},
        ],
    }))

    run("update-settings", settings, codex, desired)
    first = read(settings)
    run("update-settings", settings, codex, desired)
    second = read(settings)
    assert first == second
    assert second["keep"] is True
    assert second["packages"][0].endswith("/pi-codex")
    assert second["packages"].count("npm:custom") == 1
    assert second["packages"].count("npm:pi-subagents") == 1
    assert sum(1 for item in second["packages"] if isinstance(item, str) and "pi-codex" in item) == 1
    assert second["defaultModel"] == "test-model"

    mcp = agent_dir / "mcp.json"
    mcp.write_text(json.dumps({"mcpServers": {"custom": {"command": "custom"}}}))
    run("browser-chrome-mcp", mcp, "/opt/browser/mcp.sh", "/opt/browser/control-mcp.sh")
    first_mcp = read(mcp)
    run("browser-chrome-mcp", mcp, "/opt/browser/mcp.sh", "/opt/browser/control-mcp.sh")
    assert read(mcp) == first_mcp
    servers = first_mcp["mcpServers"]
    assert servers["custom"]["command"] == "custom"
    assert servers["browser-chrome-control"]["command"].endswith("control-mcp.sh")
    assert servers["browser-chrome-headed"]["args"] == ["headed"]
    assert servers["browser-chrome-headless"]["args"] == ["headless"]

run("verify-package", ROOT / "package.json")
with tempfile.TemporaryDirectory() as temporary:
    temp = Path(temporary)
    source_package = read(ROOT / "package.json")
    invalid_skill_roots = [
        ["./skills/general"],
        ["./skills/aad"],
        ["./skills"],
        ["./skills/aad", "./skills/general"],
    ]
    for index, skills in enumerate(invalid_skill_roots):
        candidate = json.loads(json.dumps(source_package))
        candidate["pi"]["skills"] = skills
        candidate_path = temp / f"package-{index}.json"
        candidate_path.write_text(json.dumps(candidate))
        error = run_failure("verify-package", candidate_path)
        assert "must declare both composed roots in order" in error

run("verify-subagents", ROOT / "settings/pi-subagents.config.json")
print("config component tests passed")
