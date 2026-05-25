# Codex CLI complex smoke: browser-chrome-control MCP

## Goal

Exercise the control MCP with tasks more complex than read-only status:

- headed-persistent acquire/release for saved-auth style work;
- lock contention behavior;
- policy rejection when saved auth is requested with a disposable form;
- invalid headed port rejection;
- headless-disposable guidance for public anonymous work.

These checks should not launch real private Chrome or inspect any real profile data.

## Test setup

Created a temporary fake browser-chrome skill directory under `/tmp/browser-chrome-control-codex.*` with only:

```text
fake-skill/scripts/open-headed.sh
```

The fake `open-headed.sh` prints the configured headed URL and does not launch Chrome.

Started a fake CDP endpoint on localhost:

```text
http://127.0.0.1:9299/json/version
```

The fake endpoint returned:

```json
{"Browser":"FakeChrome/1.0","Protocol-Version":"1.3"}
```

Registered temporary Codex MCP servers:

```bash
codex mcp add browser-chrome-control-fake \
  --env BROWSER_CHROME_HOME=<tmp>/home \
  --env BROWSER_CHROME_HEADED_URL=http://127.0.0.1:9299 \
  -- node skills/browser-chrome/control-mcp/server.mjs --skill-dir <tmp>/fake-skill

codex mcp add browser-chrome-control-invalid \
  --env BROWSER_CHROME_HOME=<tmp>/invalid-home \
  --env BROWSER_CHROME_HEADED_PORT=9400 \
  -- node skills/browser-chrome/control-mcp/server.mjs --skill-dir <tmp>/fake-skill
```

Temporary servers were removed after the smoke checks. The persistent Codex MCP entry left installed is only `browser-chrome-control`, pointing at this worktree for validation.

## Checks run

### 1. Saved-auth headed-persistent acquire and release

Prompt asked Codex to:

1. use only `browser-chrome-control-fake`;
2. call `browser_chrome_acquire_session` with:
   - `form=headed-persistent`
   - `purpose=codex-complex-smoke`
   - `requiresSavedAuth=true`
3. call `browser_chrome_release` with the returned lease id;
4. answer `PERSISTENT_ACQUIRE_RELEASE_OK` only if release returned `closedBrowser=false`.

Result:

```text
PERSISTENT_ACQUIRE_RELEASE_OK
```

Evidence from Codex JSONL:

- acquisition returned `mcpServer: browser-chrome-headed`;
- acquisition returned a `headed-persistent-*` lease id;
- release returned `released: true` and `closedBrowser: false`.

### 2. Lock contention

Prompt asked Codex to:

1. acquire `headed-persistent` once;
2. acquire `headed-persistent` a second time without releasing;
3. verify the second call fails busy/locked;
4. release the first lease.

Result:

```text
LOCK_CONTENTION_OK
```

Evidence from Codex JSONL:

```json
{"ok":false,"error":"headed-persistent control lease is busy/locked by another process."}
```

Release returned `closedBrowser: false`.

### 3. Saved-auth policy rejection for disposable form

Prompt asked Codex to intentionally make the agent mistake:

```json
{
  "form": "headless-disposable",
  "purpose": "saved-auth-wrong-form",
  "requiresSavedAuth": true
}
```

Result:

```text
POLICY_REJECTION_OK
```

The tool rejected the request with:

```text
Saved auth/session/profile state requires form=headed-persistent.
```

### 4. Invalid headed port rejection

Prompt asked Codex to call `browser_chrome_assert_persistent` against `browser-chrome-control-invalid`, configured with port `9400`.

Result:

```text
INVALID_PORT_OK
```

The tool rejected the config with:

```text
9200-9300
```

### 5. Public anonymous work chooses headless-disposable guidance

Prompt asked Codex to simulate a public anonymous screenshot task and call:

```json
{
  "form": "headless-disposable",
  "purpose": "public-screenshot"
}
```

Result:

```text
PUBLIC_HEADLESS_GUIDANCE_OK
```

The tool returned:

```json
{
  "form": "headless-disposable",
  "controlOwnsBrowser": false,
  "mcpServer": "browser-chrome-headless"
}
```

## Additional checks

After adding Codex stdio compatibility and annotations:

```bash
node --test skills/browser-chrome/control-mcp/*.test.mjs
bash -n skills/browser-chrome/scripts/*.sh
node --check skills/browser-chrome/control-mcp/server.mjs
```

Result:

```text
8 tests passed
syntax/checks passed
```

## Cleanup

- Killed fake CDP process.
- Removed temporary Codex MCP servers:
  - `browser-chrome-control-fake`
  - `browser-chrome-control-invalid`
- Left installed for continued validation:
  - `browser-chrome-control`

## Verdict

PASS. Codex CLI can use the control MCP for multi-step session-policy decisions, not just status. The control layer correctly guides Codex between persistent headed and disposable headless modes, enforces the saved-auth policy, enforces the headed port range, and exercises headed-persistent lock/release semantics without touching a real private Chrome session.
