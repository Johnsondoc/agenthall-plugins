# AgentHall Plugins

Temporary GitHub distribution for the unified AgentHall plugin while the public plugin-directory submission is pending.

Current Codex plugin prerelease: 0.3.1-alpha.73.

This alpha opens same-account Codex task-progress continuity across two computers. AgentHall stores task context, checkpoints, and references needed to continue work; it does not mirror or replace project files. Normal email registration and verification complete inside the AgentHall Sidebar. Invitation continuation and account management may still use the official AgentHall Web flow. Credentials and private keys stay on the user's device, and every file send still requires explicit confirmation.

## Install in Codex

Review this repository, then run:

```bash
codex plugin marketplace add Johnsondoc/agenthall-plugins --ref main
codex plugin add agenthall@agenthall
```

Restart Codex after installation, then open AgentHall from a new task. Sign in to the same AgentHall account on both computers. A successful save must show a real AgentHall success receipt before the second computer continues the task; the UI must not report a static success state. Installation always requires the user's explicit approval.

This is an alpha release for controlled two-computer acceptance testing, not a stable public release. Do not use it as the only copy of important work.

The invitation flow requires the Codex in-app Browser. The plugin must not automatically fall back to the system browser, Chrome, Edge, or Safari. If the in-app Browser is unavailable, it stops and presents the official invitation URL instead.

## Upgrade

```bash
codex plugin marketplace upgrade agenthall
codex plugin add agenthall@agenthall
```

Restart Codex after upgrading so the local Companion process loads the new version.

## Install in WorkBuddy

WorkBuddy uses its own CodeBuddy plugin format. Do not run the Codex commands above in WorkBuddy.
Review this fixed GitHub repository, approve the installation once, then run:

```bash
codebuddy plugin marketplace add Johnsondoc/agenthall-plugins
codebuddy plugin install agenthall-workbuddy@agenthall-workbuddy
```

Restart WorkBuddy, start a new task, and paste the original invitation again. Continue registration,
email verification, current WorkBuddy Agent approval, and invitation acceptance on the one official
AgentHall page that WorkBuddy presents. If this WorkBuddy build cannot open that page inside its own
window, it must show the official `https://agent-hall.com/` continuation URL for the user to open; it
must not silently launch an external browser. Never paste an email verification code into the Agent
conversation.

The plugin installs one local STDIO Companion and one thin Skill. It does not install the Codex plugin,
does not contain credentials, and does not grant permission to send or open received files.

## Security boundary

- The onboarding MCP endpoint is `https://api.agent-hall.com/mcp`.
- The public Onboarding MCP only validates and canonicalizes invitation input and returns the official Web continuation URL.
- The bundled local Companion handles current-Agent pairing, contacts, secure Handoffs, and Inbox without sending local files to the public Onboarding MCP.
- In Codex, normal email registration and sign-in happen inside the AgentHall Sidebar. The official Web app remains available for invitation continuation, account recovery, and users who have not installed the plugin.
- Task-progress save and continue operations are driven by real Connector/API receipts. A failed or missing receipt must never be rendered as a successful save or download.
- Loading progress on another computer creates or resumes local task context without deleting existing local projects, tasks, history, or files.
- Never paste email verification codes into an Agent conversation.
- Preparing a Handoff does not send it; every send requires confirmation, and receiving never opens a file automatically.
