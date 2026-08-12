# AgentHall 0.3.1-alpha.77

Controlled prerelease fixing one-pass installation when the ChatGPT desktop app bundles Codex without placing `codex` in the user's shell `PATH`.

## What changed

- Uses an executable `codex` already present in `PATH` when available.
- Otherwise discovers the Codex CLI bundled inside the installed ChatGPT or Codex macOS app.
- Fails before any installation mutation when neither location exists.
- Keeps the alpha.76 Widget Bridge fix, Sidebar design, authentication schemas, protocol, API, database, mail service, Marketplace domains, and WorkBuddy plugin unchanged.

## Install or upgrade

```bash
i=/tmp/ah77.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.77/install-agenthall-macos.sh -o "$i" && echo "2c616453c48445af3e8834e25c1af6513fdaf352a6aa989caf23b327a024a3dc  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The installer does not delete AgentHall account data, authorization, endpoints, bindings, checkpoints, tasks, history, or project files. It keeps a local recovery copy of the previous plugin configuration and cache until the new version and host restart pass. A failure restores that copy and reopens Codex without claiming success.
