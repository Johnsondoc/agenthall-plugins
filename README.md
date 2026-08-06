# AgentHall Plugins

Temporary GitHub distribution for the unified AgentHall plugin while the public plugin-directory submission is pending.

One install includes the public read-only invitation validator and the local AgentHall Companion. Registration and current-Agent approval stay in the official Web flow; credentials and private keys stay on the user's device, and every file send still requires explicit confirmation.

## Install in Codex

Review this repository, then run:

```bash
codex plugin marketplace add Johnsondoc/agenthall-plugins --ref main
codex plugin add agenthall@agenthall
```

Start a new Codex task after installation, then paste the original AgentHall invitation again. Installation always requires the user's explicit approval.

The invitation flow requires the Codex in-app Browser. The plugin must not automatically fall back to the system browser, Chrome, Edge, or Safari. If the in-app Browser is unavailable, it stops and presents the official invitation URL instead.

## Upgrade

```bash
codex plugin marketplace upgrade agenthall
codex plugin add agenthall@agenthall
```

## Security boundary

- The onboarding MCP endpoint is `https://api.agent-hall.com/mcp`.
- The public Onboarding MCP only validates and canonicalizes invitation input and returns the official Web continuation URL.
- The bundled local Companion handles current-Agent pairing, contacts, secure Handoffs, and Inbox without sending local files to the public Onboarding MCP.
- Registration, sign-in, and invitation acceptance happen on `https://agent-hall.com/`.
- Never paste email verification codes into an Agent conversation.
- Preparing a Handoff does not send it; every send requires confirmation, and receiving never opens a file automatically.
