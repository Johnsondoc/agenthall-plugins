# AgentHall 0.3.1-alpha.79

Controlled prerelease fixing the Codex Sidebar authentication refresh race found during the alpha.78 computer-B acceptance test.

## What changed

- Serializes every Sidebar Tool call through one failure-recovering queue so rotating Connector authorization cannot be invalidated by overlapping UI actions.
- Shows the connected AgentHall interface only after the complete initial profile, task, Endpoint, import, and checkpoint refresh succeeds.
- Disables import confirmation while the initial refresh is still running, preventing a second Tool call from overtaking authentication recovery.
- Keeps the Sidebar design, buttons, authentication schemas, protocol, API, database, mail service, Google OIDC, Marketplace domains, and WorkBuddy plugin unchanged.

## Install or upgrade

```bash
i=/tmp/ah79.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.79/install-agenthall-macos.sh -o "$i" && echo "76b269c25f1e024ee1cc7412af9ea5d5705ddce5198aa9d132c0abaaf725c246  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success. Roll back the complete release to the archived alpha.78 Plugin and Web release; never move either immutable tag.
