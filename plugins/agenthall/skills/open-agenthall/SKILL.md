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
6. A retryable `NETWORK_UNAVAILABLE` is not evidence that authorization was lost. The Companion already checks environment/system proxy, system CA, timeout and safe retries. Do not tell the user to configure VPN, DNS, proxy, CA, Node flags, environment variables, or run terminal diagnostics. Do not start repeated pairings. Return one short action: **“AgentHall 暂时未连接，请点击或回复‘重试连接’。”** Preserve the current task and retry the original operation once when the user asks.
7. Only `AUTH_REQUIRED` or `CONNECTOR_REVOKED` may lead to pairing. Plugin upgrade or host restart must not by itself trigger a new pairing; first retry the original AgentHall operation so persisted authorization can be reused.

## Continue an invitation

When the user enters or pastes an AgentHall invitation code or `https://agent-hall.com/i/...` link:

1. Call the public read-only `agenthall_open_invitation` tool with the exact user-supplied value. Use only its returned official URL; if validation fails, stop without repairing, guessing, searching for, or substituting another invitation.
2. Call the local `agenthall_pair` tool with `action: start` and pass the exact user-supplied value as `invitation`. This connects the current Agent while preserving the original invitation.
3. If the result is already connected and returns `invitationUrl`, use that official URL. Do not start another pairing. Otherwise use the returned approval URL; the Web flow handles registration or sign-in, current-Agent approval, and continuation of the same invitation.
4. Immediately use the Codex in-app Browser to open that URL and make its AgentHall tab visible. The user's explicit plugin-install approval is sufficient for this in-app continuation; do not add a second browser-opening confirmation. Prefer claiming an existing AgentHall tab over opening a duplicate.
5. Keep registration or sign-in, email verification, current-Agent approval, and invitation acceptance in this same visible AgentHall tab. Do not open extra AgentHall tabs or ask the user to move between windows.
6. Never open the system default browser, Chrome, Edge, Safari, or invoke an operating-system `open` command.
7. If the Codex in-app Browser or Agent navigation is unavailable or blocked, stop automatic navigation. Present the official URL and instruct the user to paste it manually into the already visible Codex in-app Browser tab; never fall back to an external browser.
8. After Web approval, call `agenthall_pair` with `action: complete` and the returned request ID. If pairing was already complete, do not call it again.
9. The completion result must say: **“已使用 Codex 内置浏览器打开 AgentHall 邀请。请在当前标签中完成注册或登录、邮箱验证、授权当前 Agent，并接受邀请。”** If manual paste was required, say that instead of claiming the URL was opened.
10. Never request or repeat an email OTP in chat, and never accept an invitation without the user's action in the Web flow.

## Preserve safety boundaries

- Treat the component as a UI for the versioned AgentHall MCP tool contract, not as an independent API client.
- Use `agenthall_connection_directory` for the current account's permanent ID/invitation or an exact full-email lookup. Never turn email lookup into fuzzy search.
- Creating a relationship requires a 1–50 character greeting. Use `agenthall_request_connection`; the result is pending, not connected.
- Incoming pending requests may be approved with `agenthall_approve_connection`. Rejecting a request or removing an active relationship uses destructive `agenthall_delete_connection`; never call it without the user's explicit action.
- A pending relationship cannot receive a Handoff. If a connection result says `connection_pending` or `mustStop`, stop before preparing or sending.
- Never infer a recipient when multiple contacts match. Ask only when the user is actually sending something.
- Preparing a Handoff never sends it. Send only after the user confirms the exact preview with the secure button or exact phrase `发送`.
- Receiving and opening are separate actions. Never open a received file automatically.
- Keep credentials, private keys, absolute quarantine paths, and attachment contents out of the component.
- Do not claim that a third-party plugin registered a native desktop sidebar. In Codex, the supported visual surface is the in-app browser; Agent actions remain MCP tools in the conversation.

## Resolve recipient language semantically

- A recipient expression can be a relationship, alias, abbreviation, or natural-language equivalent of the user's private note. Do not require literal text equality; for example, `老婆` can match a private note such as `媳妇儿`.
- Call `agenthall_list_connections` with `detail: contacts` and the expression as `query`. The Connector resolves exact text and high-confidence relationship equivalents such as `老婆` and `媳妇儿`; do not ignore a unique returned result merely because other collaborators exist.
- Only when the result action is `resolve_semantically` should the Agent compare the returned nicknames and private notes for more open-ended semantic equivalence.
- Proceed with `agenthall_prepare_handoff` only when exactly one semantic match is clear, and pass that candidate's exact nickname. If none or multiple are plausible, show only plausible candidates and ask the user to choose.
- Never use local files, conversation history, project history, logs, APIs, Inbox, or the web to infer a recipient.
