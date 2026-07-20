#!/usr/bin/env python3
"""Reject Python source embedded in any repository shell file."""
import re
import sys
from pathlib import Path

SHELL_SUFFIXES = {".sh"}
INLINE_SOURCE = re.compile(
    r"\bpython(?:3)?(?:\s|\\\n)+(?:-|-[A-Za-z]*c\b|/dev/stdin\b)",
    re.MULTILINE,
)
# Match a heredoc on a Python command line, including backslash-continued lines.
PYTHON_HEREDOC = re.compile(
    r"\bpython(?:3)?\b(?:[^\n]|\\\n)*?(?:<<-?|<<<)",
    re.MULTILINE,
)


def shell_files(root):
    for path in root.rglob("*"):
        if path.name == "pi-setup" or path.suffix in SHELL_SUFFIXES:
            if "node_modules" not in path.parts and "packages/pi-codex/node_modules" not in str(path):
                yield path


def contains_embedded_python(text):
    return bool(INLINE_SOURCE.search(text) or PYTHON_HEREDOC.search(text))


def require_rejected(script):
    if not contains_embedded_python(script):
        raise AssertionError(f"architecture guard missed forbidden form: {script!r}")


def main(argv):
    root = Path(argv[1])
    offenders = [path for path in shell_files(root) if contains_embedded_python(path.read_text())]
    if offenders:
        raise SystemExit("embedded Python source in shell: " + ", ".join(map(str, offenders)))
    # Guard self-tests are Python strings, so no forbidden shell source is checked in.
    for script in (
        "python3 - <<'PY'",
        "python -c 'print(1)'",
        "python3 /dev/stdin <<'EOF'",
        "python <<< 'print(1)'",
        "python3 tool.py <<'DATA'",
        "python3 \\\n  /dev/stdin <<'INPUT'",
    ):
        require_rejected(script)
    print("shell architecture component tests passed")


if __name__ == "__main__":
    main(sys.argv)
