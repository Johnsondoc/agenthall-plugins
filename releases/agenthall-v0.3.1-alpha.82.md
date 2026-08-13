# AgentHall 0.3.1-alpha.82

Controlled prerelease fixing the false-success state found during the alpha.81 computer-B A→B continuation acceptance test.

## What changed

- Waits for the restored Codex task's first turn to complete before reporting success.
- Sets and verifies the cloud task title, then requires the created task to be discoverable through Codex `thread/list`.
- Opens the exact Codex task after it becomes ready; a failed navigation stays retryable and never turns the AgentHall card green.
- Reopens the same completed task on a repeated click instead of creating a duplicate.
- Treats alpha.81's persisted-but-incomplete task binding as recoverable: it creates one valid replacement and removes only the stale local binding, without deleting the old Codex task or any AgentHall data.
- Requires no API or database migration and keeps authentication, Endpoint, Checkpoint, mail, Google OIDC, and WorkBuddy behavior unchanged.

## Install or upgrade

```bash
i=/tmp/ah82.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.82/install-agenthall-macos.sh -o "$i" && echo "71ea8127531468fc4e39845c159a86c549b2dc109b4c456821972674aa581f40  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

No `PATH` change or symlink is required. Codex closes and reopens automatically. Start a new task after it reopens, then open AgentHall.

## Safety and rollback

The plugin fix changes only local Codex continuation completion, visibility, binding, and navigation gates. The installer does not delete AgentHall account data, authorization, endpoints, bindings unrelated to the selected continuation, checkpoints, tasks, history, or project files. Roll back the Plugin and Web surfaces to the archived alpha.81 release; keep the current alpha.81 API and migration 19, and never run a database down migration for this change.
