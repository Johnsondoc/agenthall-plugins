# AgentHall 0.3.1-alpha.84

Public prerelease consolidating the V0.3.1 Codex two-computer continuation path around one recoverable Operation Contract and a host-verified installer lifecycle. This release is **partial** until the real A → B → A continuation acceptance completes.

## What changed

- Uses one private Operation journal, owner lease, generation, and explicit command/query boundary for save, restore, authentication, import, and continuation work instead of scattered retries.
- Resumes the same Operation and Codex task after interruption; repeated clicks no longer create another save, restore, authentication action, or same-title task candidate.
- Opens the authenticated AgentHall business surface directly in the host's right Sidebar. The Launcher remains only as a compatibility fallback for hosts without the direct surface capability.
- Recovers after a Sidebar remount without requiring a refresh, scroll, repeated login, repeated consent, or another Operation.
- Preserves committed task progress and durable UI state across same-task Sidebar tab switches. When the host creates a new WebView after switching Codex tasks, AgentHall reconnects and reloads authoritative task data automatically.
- Enables local import immediately after the user accepts the import explanation; unrelated background reads no longer keep the button disabled.
- Keeps email and Google authentication resumable and preserves the existing 90-day Connector authorization window.
- Replaces passive process timing with an active Codex app-server Runtime probe. The installer asks the host to load AgentHall, then verifies the exact version, Tool catalog, Sidebar resource and digest, process ownership, and current cache before reporting success. Lazy MCP startup is accepted; wrong, backup, or stale Runtime activation still rolls back automatically.

## Accepted host boundary

Switching between Codex tasks may briefly recreate the right-Sidebar WebView, show the AgentHall connection tunnel, and reload task data. Automatic recovery is accepted for this V0.3.1 prerelease. Returning to a Launcher, a persistent black screen, manual refresh/scroll/reopen, repeated login or consent, lost committed progress, or a duplicate Operation remains a failure.

## Install or upgrade on macOS

```bash
i=/tmp/ah84.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.84/install-agenthall-macos.sh -o "$i" && echo "d576d087f6662ae52cd354c871e2d559983c9d32bef2237b8b5fcdae9f062b61  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change, manual cache cleanup, uninstall, patch, or symlink is required. Codex closes and reopens automatically. Run the command once; if validation fails, stop and use the preserved rollback instead of adding recovery commands.

## Distribution, deployment, and rollback

- The Codex plugin, public Marketplace, immutable annotated Tag, GitHub Prerelease, production Web installation copy, and fixed installer digest use the same `0.3.1-alpha.84` Release Version.
- No API, database, migration, mail, Google OIDC, account, credential, Context data, or WorkBuddy deployment is included.
- The installer does not delete AgentHall accounts, authorization, endpoints, bindings, checkpoints, projects, tasks, history, memories, or project files.
- The archived `0.3.1-alpha.82` public release remains the rollback target, and the immutable `0.3.1-alpha.83` test prerelease remains available as historical evidence. Old Tags are never moved or overwritten.

## Acceptance still required

- One official-channel upgrade on computer B with current-Runtime verification.
- One real A → B → A context continuation using one stable Operation and no duplicate Codex task or saved progress.
