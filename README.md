# AgentHall Plugins

Temporary GitHub distribution for the unified AgentHall plugin while the public plugin-directory submission is pending.

Current Codex plugin release: 0.3.1-alpha.81.

After installation, normal email registration and verification complete inside the AgentHall Sidebar without opening a browser. Invitation continuation and account management may still use the official AgentHall Web flow. One install includes the public read-only invitation validator and the local AgentHall Companion; credentials and private keys stay on the user's device, and every file send still requires explicit confirmation.

## Install or upgrade in Codex on macOS

Review the version-pinned installer, then run this one command in Terminal:

```bash
i=/tmp/ah81.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.81/install-agenthall-macos.sh -o "$i" && echo "eeb81b1d2e0d7e0cbfd6b12193f8d1cde47075fe6a29307ce386cabc341123c6  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

The installer uses the immutable `agenthall-v0.3.1-alpha.81` tag for clean installs and upgrades. It starts one self-contained background worker without leaving a persistent launchd job, automatically finds Codex either in `PATH` or inside the installed ChatGPT/Codex app, then verifies the downloaded installer and every Plugin, MCP, Skill, Sidebar, and logo artifact; requests Codex to quit normally before replacing any plugin files; preserves a recoverable copy of the previous installation; reopens Codex; and verifies that the current Plugin runtime is loaded. If Codex initially loads a transaction backup runtime, the installer performs one bounded full restart automatically; if the current runtime still does not load, it restores the previous installation instead of reporting success. It does not delete AgentHall accounts, authorization, endpoints, bindings, checkpoints, projects, tasks, history, or project files.

After Codex reopens, start a new task and open AgentHall. Plugin capabilities are loaded into new tasks after installation. Email registration and sign-in complete inside the AgentHall Sidebar; paste the original invitation again when you are ready to accept the relationship. Installation always requires the user's explicit approval. A recipient may also register and connect the relationship on the Web first, receive an asynchronous Handoff on the server, and install this latest plugin later to claim it.

The invitation flow requires the Codex in-app Browser. The plugin must not automatically fall back to the system browser, Chrome, Edge, or Safari. If the in-app Browser is unavailable, it stops and presents the official invitation URL instead.

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
- Never paste email verification codes into an Agent conversation.
- Preparing a Handoff does not send it; every send requires confirmation, and receiving never opens a file automatically.
