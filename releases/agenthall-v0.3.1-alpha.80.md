# AgentHall 0.3.1-alpha.80

Controlled prerelease fixing the Codex Sidebar login loop and the one-pass installer backup-runtime regression found during the alpha.79 computer-B acceptance test.

## What changed

- Treats a successful AgentHall Profile read as the authentication boundary; later task, Endpoint, import, or checkpoint read errors stay on the main view instead of incorrectly returning to login.
- Keeps genuine `AUTH_REQUIRED` and `CONNECTOR_REVOKED` Profile results on the login view.
- Verifies after installation that Codex loaded the current alpha.80 MCP runtime. If the first launch uses a transaction backup runtime, the installer performs one bounded full restart automatically.
- Restores the previous installation instead of claiming success if the current runtime still does not load.
- Keeps the Sidebar design, buttons, Tool schemas, protocol, API, database, mail service, Google OIDC, account data, Context data, and WorkBuddy plugin unchanged.

## Install or upgrade

```bash
i=/tmp/ah80.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.80/install-agenthall-macos.sh -o "$i" && echo "e88a7438c1e82d9a8d3c115419870657724aea711bac182e9fe7901dd4e3f792  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the target files and current runtime pass. A failure restores that copy and reopens Codex without claiming success. Roll back the complete release to the archived alpha.79 Plugin and Web release; never move either immutable tag.
