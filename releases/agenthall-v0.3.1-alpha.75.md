# AgentHall 0.3.1-alpha.75

Controlled prerelease fixing Sidebar authentication for public Marketplace installs.

## What changed

- Removes the internal-only API base override from the public Codex Companion.
- Keeps the public Onboarding MCP on its dedicated API endpoint while the local Companion uses the production business origin.
- Adds a final Marketplace-package gate that rejects any internal API-base override on the local Companion.
- Keeps the Sidebar design, controls, authentication flow, protocol, API, database schema, and WorkBuddy plugin unchanged from alpha.74.

## Install or upgrade

```bash
i=/tmp/ah75.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.75/install-agenthall-macos.sh -o "$i" && echo "a8b23f194a81950588945792485946558bd02e84fc5424e4eeb8b375cc95de5a  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success.
