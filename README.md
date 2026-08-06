# AgentHall Plugins

Temporary GitHub distribution for the unified AgentHall plugin while the public plugin-directory submission is pending.

Registration, email verification, and relationship setup can be completed in the official AgentHall Web flow before installing a plugin. Install AgentHall when you want the Agent to send or receive files. One install then includes the public read-only invitation validator and the local AgentHall Companion; credentials and private keys stay on the user's device, and every file send still requires explicit confirmation.

## Install in Codex

Review this repository, then run:

```bash
codex plugin marketplace add Johnsondoc/agenthall-plugins --ref main
codex plugin add agenthall@agenthall
```

Start a new Codex task after installation, then paste the original AgentHall invitation again. Installation always requires the user's explicit approval. A recipient may register and connect the relationship on the Web first, receive an asynchronous Handoff on the server, and install this latest plugin later to claim it.

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
- Registration, sign-in, and invitation acceptance happen on `https://agent-hall.com/`.
- Never paste email verification codes into an Agent conversation.
- Preparing a Handoff does not send it; every send requires confirmation, and receiving never opens a file automatically.
