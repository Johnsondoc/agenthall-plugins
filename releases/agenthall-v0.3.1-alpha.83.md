# AgentHall 0.3.1-alpha.83 Test Prerelease

This is a controlled public test prerelease for one computer-B installation through the immutable GitHub download channel. It is **partial** until the real A → B → A continuation acceptance completes. It does not advance the public Marketplace `main` branch or the current alpha.82 installation pointer.

## What changed

- Replaces scattered save, restore, authentication, and continuation retries with one recoverable Operation Contract backed by a private journal, owner lease, generation, and explicit command/query tools.
- Prevents ambiguous mutating Tool results from being replayed as a second save, restore, authentication action, or Codex task.
- Makes the Codex Adapter resume the same operation and task instead of creating repeated same-title candidates.
- Opens the authenticated AgentHall business surface directly in the host's persistent right Sidebar; the legacy Launcher remains only as a compatibility fallback.
- Keeps email and Google authentication resumable after transient host or network interruption and preserves the existing 90-day Connector authorization window.
- Enables the local import action as soon as the user accepts the import explanation; unrelated background reads no longer keep the button disabled.
- Recovers automatically after a Codex task remount without a manual click, refresh, scroll, re-login, or repeated Operation.
- Activates immutable plugin bytes only after Codex and AgentHall runtimes exit cleanly, rejects backup/stale runtimes, and verifies the current runtime before reporting success.

## Known test boundary

Switching between Codex tasks can briefly show the host connection tunnel and reload AgentHall data before the business surface returns. Automatic recovery is accepted for this V0.3.1 test; preserving the exact active tab, expanded rows, selection, and scroll position across a newly created WebView is deferred. A Launcher, black screen, manual recovery, lost committed progress, or duplicate Operation remains a failure.

## Install or upgrade on computer B

```bash
i=/tmp/ah83.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.83/install-agenthall-macos.sh -o "$i" && echo "350723899a9e0a41ba95d6096abaf321b627510002a84d9ad193707c0f844248  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. This command is intended to be run once on computer B; do not apply additional patches or cache-cleaning steps.

## Distribution, deployment, and rollback

- Public Marketplace `main`, the current installation pointer, and Web installation copy remain on `0.3.1-alpha.82` during this test.
- No Web, API, database, migration, mail, Google OIDC, or WorkBuddy deployment is included.
- The installer does not delete AgentHall accounts, authorization, endpoints, bindings, checkpoints, projects, tasks, history, memories, or project files.
- If the B-machine acceptance fails, stop the rollout and reinstall the archived `0.3.1-alpha.82`; do not move or overwrite this immutable Tag. Any fix must use a new version.

## Acceptance still required

- One official-channel installation on computer B with current-runtime verification.
- One real A → B → A context continuation with a single Operation and no duplicate Codex task or saved progress.
