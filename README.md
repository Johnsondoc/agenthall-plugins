# AgentHall Plugins

Temporary GitHub distribution for the AgentHall Onboarding plugin while the public plugin-directory submission is pending.

The package contains only the public, read-only invitation onboarding plugin. It does not contain the local AgentHall Companion, local file access, credentials, email verification codes, or invitation secrets.

## Install in Codex

Review this repository, then run:

```bash
codex plugin marketplace add Johnsondoc/agenthall-plugins --ref main
codex plugin add agenthall-onboarding@agenthall
```

Start a new Codex task after installation, then paste the original AgentHall invitation again. Installation always requires the user's explicit approval.

The invitation flow requires the Codex in-app Browser. The plugin must not automatically fall back to the system browser, Chrome, Edge, or Safari. If the in-app Browser is unavailable, it stops and presents the official invitation URL instead.

## Upgrade

```bash
codex plugin marketplace upgrade agenthall
codex plugin add agenthall-onboarding@agenthall
```

## Security boundary

- The onboarding MCP endpoint is `https://api.agent-hall.com/mcp`.
- The plugin only validates and canonicalizes AgentHall invitation input and returns the official Web continuation URL.
- Registration, sign-in, and invitation acceptance happen on `https://agent-hall.com/`.
- Never paste email verification codes into an Agent conversation.
- Local file collaboration requires the separate AgentHall Companion and a separate installation approval.
