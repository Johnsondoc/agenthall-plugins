# AgentHall 0.3.1-alpha.73

Controlled prerelease for same-account Codex task-progress continuity across two computers.

## Included

- Three-column Launcher scene with the real AgentHall Sidebar highlighted by a rounded purple halo.
- Real save/continue status driven by Connector and API receipts; success is never reported statically.
- Same-checkpoint protection on the current endpoint and non-destructive recovery when a native local task is absent.
- Stable AgentHall task identity across A → B → A continuation.

## Install or upgrade

```bash
codex plugin marketplace add Johnsondoc/agenthall-plugins --ref main
codex plugin marketplace upgrade agenthall
codex plugin add agenthall@agenthall
```

Restart Codex and start a new task before using the plugin. Both computers must install exactly `0.3.1-alpha.73` for the controlled acceptance test.

## Safety and rollback

AgentHall stores task context, checkpoints, and references needed for continuation; it does not mirror or replace project files. Existing local projects, tasks, history, and files must be preserved. If the alpha cannot be loaded, install a previously archived Marketplace tag or restore the retained Personal alpha.72 package; do not delete local AgentHall state.
