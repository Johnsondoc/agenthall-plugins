# AgentHall 0.3.1-alpha.74

Controlled prerelease for one-pass macOS installation and same-account Codex task-progress continuity across two computers.

## What changed

- Adds one version-pinned macOS install/upgrade entry for clean, legacy Marketplace, and Personal Alpha installations.
- Verifies the installer plus Plugin, MCP, Skill, Sidebar, and logo artifacts before reporting success.
- Requests Codex to exit normally before changing plugin files, so an active task never points at a cache removed by the upgrade.
- Restarts Codex automatically and restores the prior installation if installation, verification, or restart fails.
- Keeps the AgentHall V0.3.1 product behavior, protocol, API, database schema, Web release, Launcher background, copy, and controls unchanged from alpha.73.

## Install or upgrade

```bash
i=/tmp/ah74.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.74/install-agenthall-macos.sh -o "$i" && echo "b695afd6f838cac17b8551605188881ace4bed28d4e09cbde9eedfcff275a8a3  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success.
