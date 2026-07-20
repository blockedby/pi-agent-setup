#!/usr/bin/env python3
"""Direct regression tests for the standalone Pi setup JSON component."""
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path


def run(component, *args):
    subprocess.run([sys.executable, str(component), *map(str, args)], check=True)


def digest(path):
    return hashlib.sha256(path.read_bytes()).digest()


def main(argv):
    component = Path(argv[1]) / "scripts/lib/config-json.py"
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        package = root / "package.json"
        package.write_text('{"pi":{"extensions":["./extensions/ready-notify.ts"]}}\n')
        run(component, "verify-package-extensions", package)

        subagents = root / "subagents.json"
        subagents.write_text(
            json.dumps(
                {
                    "scheduledRuns": {"enabled": True},
                    "control": {
                        "needsAttentionAfterMs": 180000,
                        "notifyOn": ["needs_attention"],
                    },
                }
            )
            + "\n"
        )
        run(component, "verify-subagents", subagents)


        source = root / "mcp-source.json"
        source.write_text('{"mcpServers":{"example":{"command":"npx"}}}\n')
        mcp = root / "mcp.json"
        mcp.write_text('{"mcpServers":{"keep":{"command":"keep"}}}\n')
        run(component, "merge-mcp", mcp, source, "test")
        first = digest(mcp)
        run(component, "merge-mcp", mcp, source, "test")
        assert first == digest(mcp)
        assert set(json.loads(mcp.read_text())["mcpServers"]) == {"keep", "example"}

        chrome = root / "chrome.json"
        chrome.write_text('{"mcpServers":{"keep":{"command":"keep"}}}\n')
        run(component, "browser-chrome-mcp", chrome, "/opt/chrome-mcp.sh")
        first = digest(chrome)
        run(component, "browser-chrome-mcp", chrome, "/opt/chrome-mcp.sh")
        servers = json.loads(chrome.read_text())["mcpServers"]
        assert first == digest(chrome)
        assert set(servers) == {"keep", "browser-chrome-headed", "browser-chrome-headless"}
        assert servers["browser-chrome-headed"]["args"] == ["headed"]
        assert servers["browser-chrome-headless"]["idleTimeout"] == 1

        settings = root / "settings.json"
        desired = root / "desired.json"
        codex = root / "codex"
        codex.mkdir()
        settings.write_text('{"packages":["git:github.com/blockedby/pi-codex","other-package"],"keep":true}\n')
        desired.write_text('{"defaultProvider":"provider","defaultModel":"model","defaultThinkingLevel":"low"}\n')
        run(component, "update-settings", settings, codex, desired)
        value = json.loads(settings.read_text())
        assert value["keep"] is True and value["packages"][1] == "other-package"
        assert value["defaultProvider"] == "provider"
    print("config component tests passed")


if __name__ == "__main__":
    main(sys.argv)
