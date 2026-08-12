# AgentHall 0.3.1-alpha.76

Controlled prerelease fixing Sidebar-initiated Tool calls in the current Codex host.

## What changed

- Uses the documented `window.openai.callTool` compatibility API first when the Codex/ChatGPT host exposes it.
- Preserves the standard MCP Apps `tools/call` bridge as the portable fallback.
- Uses the documented `window.openai.openExternal` compatibility API first for Google authorization, with standard `ui/open-link` fallback.
- Keeps the Sidebar design, controls, authentication schemas, protocol, API, database, mail service, Marketplace domains, and WorkBuddy plugin unchanged from alpha.75.

## Install or upgrade

```bash
i=/tmp/ah76.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.76/install-agenthall-macos.sh -o "$i" && echo "7ae68e6f8976234e87d89ac47f16229516fef067f95d064fd2180f7dfb9e2a55  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success.
