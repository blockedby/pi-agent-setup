# Secret boundary

This repository is public-friendly but must contain no secrets or raw private operational evidence.

Do not commit:

- `$HOME/.pi/agent/auth.json`
- `$HOME/.codex/auth.json`, `$HOME/.codex/config.toml`, Codex logs/state/cache
- API keys, OAuth refresh/access tokens, cookies, bot tokens, webhooks, chat IDs, or subscription URLs
- SSH private keys or deploy keys
- Pi sessions/history/cache
- Private host inventory, private domains, access handoffs, or server-specific runbooks
- Browser profile directories such as `$HOME/.cache/browser-chrome/` or any Chrome user-data-dir
- Chrome cookies, saved sessions, local storage, passwords, extension state, or DevTools runtime state
- Raw production/customer/user logs or copied agent transcripts with private context

Use ignored local files for machine-specific settings:

- `.env` / `.env.local`
- `settings/*.local.json`
- shell profile exports outside the repo

Auth import is a separate explicit operation:

```bash
CONFIRM_COPY_PI_AUTH=1 TARGET_HOST=<host> scripts/import-auth-remote.sh
```

The script copies the file with mode `600` and does not print contents. It is for a user's own controlled machines only; never use it to copy third-party credentials or commit the copied file.
