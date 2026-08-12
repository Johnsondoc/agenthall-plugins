# AgentHall 0.3.1-alpha.81

Controlled prerelease fixing the Endpoint quota mismatch found during the alpha.80 computer-B import acceptance test.

## What changed

- Uses one shared PostgreSQL eligibility scope for both the visible Endpoint list and the two-device quota.
- Stops an active legacy Endpoint whose Connector belongs to another account from invisibly consuming a device slot.
- Preserves the two-visible-device limit: after two eligible devices are registered, a real third device is still rejected.
- Requires no database migration and does not delete or rewrite existing Endpoint, Connector, account, task, checkpoint, or project data.
- Keeps the Sidebar design, authentication flow, Tool schemas, protocol, mail service, Google OIDC, and WorkBuddy plugin behavior unchanged.

## Install or upgrade

```bash
i=/tmp/ah81.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.81/install-agenthall-macos.sh -o "$i" && echo "eeb81b1d2e0d7e0cbfd6b12193f8d1cde47075fe6a29307ce386cabc341123c6  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The application fix changes only the Endpoint quota query and requires no destructive data cleanup. The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. Roll back the Plugin and Web surfaces to the archived alpha.80 release and the API to the still-deployed alpha.62 release; never move either immutable tag and never run a database down migration for this change.
