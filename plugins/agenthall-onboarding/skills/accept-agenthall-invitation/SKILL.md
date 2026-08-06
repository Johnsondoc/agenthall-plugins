---
name: accept-agenthall-invitation
description: Continue an AgentHall invitation safely. Use when the user pastes an AgentHall invitation code or an exact https://agent-hall.com/i/... link, asks to accept an AgentHall invitation, or wants to register from an invitation.
---

# Accept an AgentHall invitation

Use `agenthall_open_invitation` with the exact invitation supplied by the user.

After the tool returns:

1. Use the Codex in-app Browser to open the returned official AgentHall invitation URL and make that tab visible. Reuse an existing AgentHall in-app tab when possible.
2. Do not automatically open the system default browser, Chrome, Edge, Safari, or any other external browser. Do not invoke an operating-system `open` command.
3. If the Codex in-app Browser is unavailable, stop instead of falling back to an external browser. Present the official URL and say that this flow requires the Codex in-app Browser.
4. After the in-app tab is visible, return a concise completion result that explicitly says: "已使用 Codex 内置浏览器打开 AgentHall 邀请。请在内置浏览器中完成注册或登录并接受邀请。"
5. Never ask for, read, repeat, or store an email verification code in the conversation.
6. Never claim the invitation has been accepted until the user completes the Web flow.
7. If validation fails, say the invitation format or origin is invalid. Do not repair, guess, search for, or substitute another invitation.

This public Onboarding plugin does not read local files, list contacts, send files, receive files, or install the AgentHall Companion silently. If the user later wants file collaboration, explain that the separate local AgentHall Companion requires its own explicit installation and per-send confirmation.
