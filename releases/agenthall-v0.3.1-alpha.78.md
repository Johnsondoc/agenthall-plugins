# AgentHall 0.3.1-alpha.78

Controlled prerelease fixing the Codex Sidebar authentication recovery path and the macOS one-pass installer worker lifecycle.

## What changed

- Uses the standard MCP Apps `tools/call` route first, with `window.openai.callTool` only as a compatibility fallback.
- Treats an already-connected authentication response as success and refreshes the Sidebar instead of reporting `APP_TOOL_CALL_FAILED`.
- Preserves stable structured business error codes while keeping raw host errors private.
- Runs one self-contained macOS installer worker without leaving a persistent launchd job.
- Keeps the Sidebar design, authentication schemas, protocol, API, database, mail service, Marketplace domains, and WorkBuddy plugin unchanged.

## Install or upgrade

```bash
i=/tmp/ah78.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.78/install-agenthall-macos.sh -o "$i" && echo "e9a0dcfacb7e3739c2c23cbd540ff14567b9292ba9c220dec6488c9e740f0654  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success. Roll back the complete release to the archived alpha.77 Plugin and Web release; never move either immutable tag.
