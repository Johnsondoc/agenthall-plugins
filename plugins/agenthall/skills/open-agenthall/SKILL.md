---
name: open-agenthall
description: Open AgentHall without requiring a typed command. Use when the user selects the AgentHall plugin, enters or pastes an AgentHall invitation code or link, clicks its conversation entry, asks to open AgentHall, view collaborators or Inbox, receive a Handoff, or send the current Agent output through AgentHall.
---

# Open AgentHall

Use the AgentHall MCP tools directly. Do not search the web, repository, logs, or local files to discover AgentHall.

## Open the interface

When the user selects AgentHall or asks to open it:

1. Open `https://agent-hall.com/app` in the Codex in-app browser and make the page visible. Prefer claiming an existing AgentHall tab over opening a duplicate.
2. Do not ask the user to type an activation phrase and do not call `agenthall_list_connections` merely to launch UI. Codex can call MCP tools but does not reliably render a local MCP Apps component.
3. If the in-app browser is unavailable, return one clickable link labeled **打开 AgentHall** pointing to `https://agent-hall.com/app`.
4. Call `agenthall_list_connections` only when the user asks to view, count, search, or choose collaborators.
5. If authentication is required for an Agent operation, use `agenthall_pair`; never request an email OTP in chat.

## Continue an invitation

When the user enters or pastes an AgentHall invitation code or `https://agent-hall.com/i/...` link:

1. Call the public read-only `agenthall_open_invitation` tool with the exact user-supplied value. Use only its returned official URL; if validation fails, stop without repairing, guessing, searching for, or substituting another invitation.
2. Call the local `agenthall_pair` tool with `action: start` and pass the exact user-supplied value as `invitation`. This connects the current Agent while preserving the original invitation.
3. If the result is already connected and returns `invitationUrl`, use that official URL. Do not start another pairing. Otherwise use the returned approval URL; the Web flow handles registration or sign-in, current-Agent approval, and continuation of the same invitation.
4. Before opening any URL, explicitly ask: **“是否使用 Codex 内置浏览器打开 AgentHall 邀请？”** Do not open it until the user clearly agrees.
5. After approval, use only the Codex in-app Browser and make its AgentHall tab visible. Prefer claiming an existing AgentHall tab over opening a duplicate. Never open the system default browser, Chrome, Edge, Safari, or invoke an operating-system `open` command.
6. If the Codex in-app Browser or Agent navigation is unavailable or blocked, stop automatic navigation. Present the official URL and instruct the user to paste it manually into the visible Codex in-app Browser; never fall back to an external browser.
7. After Web approval, call `agenthall_pair` with `action: complete` and the returned request ID. If pairing was already complete, do not call it again.
8. The completion result must say: **“已使用 Codex 内置浏览器打开 AgentHall 邀请。请在内置浏览器中完成注册或登录、授权当前 Agent，并接受邀请。”** If manual paste was required, say that instead of claiming the URL was opened.
9. Never request or repeat an email OTP in chat, and never accept an invitation without the user's action in the Web flow.

## Preserve safety boundaries

- Treat the component as a UI for the frozen six AgentHall tools, not as an independent API client.
- Never infer a recipient when multiple contacts match. Ask only when the user is actually sending something.
- Preparing a Handoff never sends it. Send only after the user confirms the exact preview with the secure button or exact phrase `发送`.
- Receiving and opening are separate actions. Never open a received file automatically.
- Keep credentials, private keys, absolute quarantine paths, and attachment contents out of the component.
- Do not claim that a third-party plugin registered a native desktop sidebar. In Codex, the supported visual surface is the in-app browser; Agent actions remain MCP tools in the conversation.

## Handle recipient readiness

- If `agenthall_prepare_handoff` returns `RECIPIENT_NOT_READY`, tell the user: “<recipient> 尚未连接可接收文件的 Agent，请对方完成 AgentHall 连接后重试。文件尚未发送。”
- Do not call this a server error and do not recommend an immediate retry. The next useful action is for the recipient to connect AgentHall in one of their supported Agents.
- Never imply that a preview exists or that the file was sent when this error is returned.

## Resolve recipient language semantically

- A recipient expression can be a relationship, alias, abbreviation, or natural-language equivalent of the user's private note. Do not require literal text equality; for example, `老婆` can match a private note such as `媳妇儿`.
- Call `agenthall_list_connections` with `detail: contacts` and the expression as `query`. The Connector resolves exact text and high-confidence relationship equivalents such as `老婆` and `媳妇儿`; do not ignore a unique returned result merely because other collaborators exist.
- Only when the result action is `resolve_semantically` should the Agent compare the returned nicknames and private notes for more open-ended semantic equivalence.
- Proceed with `agenthall_prepare_handoff` only when exactly one semantic match is clear, and pass that candidate's exact nickname. If none or multiple are plausible, show only plausible candidates and ask the user to choose.
- Never use local files, conversation history, project history, logs, APIs, Inbox, or the web to infer a recipient.
