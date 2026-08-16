# AgentHall 0.3.1-alpha.103 Test Prerelease

This is an authorized, immutable GitHub test prerelease for saving the exact current Codex task to AgentHall with one natural-language command. It remains **partial** until computer B, clean installation, and the first-save plus incremental-update acceptance gates complete. It does not advance the public Marketplace `main` branch or the current alpha.84 installation pointer.

## What changed

- In the current Codex task, an affirmative command such as `保存到 AgentHall`, `更新到 AgentHall`, or `上传到 AgentHall` can save without opening the Sidebar or asking for another confirmation.
- Adds one model-only, zero-argument `agenthall_context_save_current` Tool. It uses Codex-provided hidden current-thread metadata and rejects missing or conflicting identity instead of guessing from a title, recent task, working directory, or Sidebar selection.
- The first save creates one separate cloud task and checkpoint for the exact native task. Later saves reuse its exact binding and append a child checkpoint to the same cloud task.
- Reuses the existing Portable Context, revision resolution, LocalOperation journal, Checkpoint DAG, authorization, timeout, and durable-success contracts. It does not upload hidden reasoning, credentials, project files, or unapproved full conversations.
- Questions, quoted examples, or ordinary discussion of the save phrase do not trigger a mutation. Result-unknown mutations are not replayed automatically.
- Keeps the alpha.102 Sidebar durable-success precedence fix: a confirmed succeeded/100% operation wins over stale loading and error presentation.

## Install or upgrade on macOS

```bash
i=/tmp/ah103.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.103/install-agenthall-macos.sh -o "$i" && echo "a927620965ee36d0719886ce93bfaaecda21154ae1143c5ea842ba327c5b2b54  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change, cache cleanup, uninstall, patch, or symlink is required. Codex closes and reopens automatically. The installer verifies the immutable 103 Plugin, MCP, Skill, Sidebar, logo, Runtime, and Tool catalog before reporting success, and restores the preserved previous installation if activation fails.

After Codex reopens, use a current task and type an affirmative save command once. Do not repeat the command while an operation result is unknown. Opening the Sidebar is optional and does not create a second operation.

## Verified evidence

- Source commit: `8773d01c200c98691bbaa134174b66ef2e521bb2`.
- Context/Operation/MCP targeted tests: 67 passed, 0 failed.
- Plugin and isolated artifact contracts: 5 passed, 0 failed.
- Regular repository tests: 189 passed, 0 failed.
- AgentHall suite: 448 passed, 0 failed, 11 conditionally skipped.
- TypeScript, ESLint, formatting, release alignment, and full-repository sensitive-information scan passed.
- Existing-user upgrade and active alpha.103 Runtime verification passed on computer A with 36 Runtime Tools and the versioned Sidebar resource.

## Distribution, deployment, and rollback

- Public Marketplace `main`, the current installation pointer, and the public README remain on `0.3.1-alpha.84` during this test.
- No API, Web, database, migration, mail, authentication schema, invitation copy, or WorkBuddy deployment is included.
- The installer does not delete AgentHall accounts, authorization, endpoints, bindings, tasks, checkpoints, history, memories, project files, or existing local operations.
- The public rollback target remains the archived `0.3.1-alpha.84`. The A-machine internal rollback copy is alpha.102. Do not move or overwrite this immutable Tag; any fix must use a new version.

## Acceptance still required

- Install the same immutable bytes on computer B and verify the active Runtime after host restart.
- Complete a clean installation gate.
- In one existing task, run one first save and one later incremental save, then verify one cloud task, a parent/child checkpoint chain, succeeded/100% operations, and no duplicate task or checkpoint.
