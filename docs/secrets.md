# Secret boundary

This repository is private but must still contain no secrets.

Do not commit:

- `~/.pi/agent/auth.json`
- API keys, OAuth refresh/access tokens, cookies
- SSH private keys or deploy keys
- Pi sessions/history/cache
- Hermes config files containing secrets
- plaintext server inventory/access handoff files

Auth import is a separate explicit operation:

```bash
CONFIRM_COPY_PI_AUTH=1 scripts/import-auth-vps.sh
```

The script copies the file with mode `600` and does not print contents.
