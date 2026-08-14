# AgentHall Plugins

Temporary GitHub distribution for the unified AgentHall plugin while the public plugin-directory submission is pending.

Current Codex plugin release: 0.3.1-alpha.84.

After installation, normal email registration and verification complete inside the AgentHall Sidebar without opening a browser. Invitation continuation and account management may still use the official AgentHall Web flow. One install includes the public read-only invitation validator and the local AgentHall Companion; credentials and private keys stay on the user's device, and every file send still requires explicit confirmation.

## Install or upgrade in Codex on macOS

Review the version-pinned installer, then run this one command in Terminal:

```bash
i=/tmp/ah84.sh; curl -fsSL https://raw.githubusercontent.com/Johnsondoc/agenthall-plugins/agenthall-v0.3.1-alpha.84/install-agenthall-macos.sh -o "$i" && echo "d576d087f6662ae52cd354c871e2d559983c9d32bef2237b8b5fcdae9f062b61  $i" | shasum -a 256 -c - && /bin/bash "$i"
```

The installer uses the immutable `agenthall-v0.3.1-alpha.84` tag for clean installs and upgrades. It starts one self-contained background worker without leaving a persistent launchd job, automatically finds the Codex runtime bundled with the installed ChatGPT/Codex app, and verifies the downloaded installer plus every Plugin, MCP, Skill, Sidebar, and logo artifact. Before replacing plugin files it requests Codex to quit normally and preserves one recoverable copy of the previous installation. After reopening Codex, it actively asks the host app-server to load AgentHall and verifies the exact runtime version, Tool catalog, Sidebar resource, resource digest, process ownership, and current cache before reporting success. A delayed or lazy MCP start is therefore handled without asking the user to retry; a wrong, backup, or stale runtime still causes an automatic rollback. It does not delete AgentHall accounts, authorization, endpoints, bindings, checkpoints, projects, tasks, history, or project files.

After Codex reopens, start a new task and select AgentHall. The authenticated business surface opens in the host's right Sidebar; the Launcher is retained only as a compatibility fallback for hosts that cannot open that surface directly. Email registration and sign-in complete inside the AgentHall Sidebar, and a successful authorization remains valid for up to 90 days. Installation always requires the user's explicit approval. A recipient may also register and connect the relationship on the Web first, receive an asynchronous Handoff on the server, and install this latest plugin later to claim it.

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
