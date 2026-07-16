---
name: aad-target-branch-preparation
description: Use when finalizing an AAD branch safely against its explicit or reliably inferred target branch.
---

# AAD Target Branch Preparation

Use after fresh verification. The target is an explicit `--target` from the user/prompt or repository guidance; otherwise `target-branch-prepare` infers the recorded creation target (`branch.<feature>.aadTarget`) or a still-resolvable `branch: Created from <target>` reflog entry. It fails closed rather than guessing. `--base` remains a compatibility alias. Remote defaults to `origin` and is set with `--remote`.

1. Verify the feature branch, open/update its PR targeting `<target>`, and record the repository identity.
2. Run `aad-finalization-helper.sh target-branch-prepare --target <target> --remote <remote>`. Re-run regression checks if its result says content changed, conflicts occurred, or a fix-up was added.
3. Before remote merge, from the target checkout, fetch `<remote> <target>` and require: current branch is `<target>`; workspace is clean; and `HEAD` exactly equals `<remote>/<target>`. Otherwise stop without merge or mutation.
4. After an authorized remote merge (or confirmed already merged), run `aad-finalization-helper.sh target-branch-sync --target <target> --remote <remote>`. When invoked from the target checkout, sync defaults to its current branch. It only permits clean equal no-op or behind-only `git merge --ff-only <remote>/<target>`; ahead, diverged, dirty, wrong checkout, unknown target, push, stash, rebase, and reset are forbidden. Requested cleanup occurs only after this success.

## Provenance

Worktree management records `git config branch.<feature>.aadTarget <target>` immediately after creating a feature branch. This is preferred provenance. Reflog fallback is intentionally narrow and accepted only when the origin branch still resolves locally. If neither is reliable, pass `--target`; do not assume a default branch.

## Bundled helpers

```bash
bash "$HELPER" target-branch-prepare --target <target> --remote origin
bash "$HELPER" target-branch-sync --target <target> --remote origin
```

`AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR` is test-only. The dispatcher resolves installed bundled scripts by default. Helpers never authorize weaker safety rules.
