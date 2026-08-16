---
name: open-agenthall
description: Open AgentHall or save the exact current Codex task without requiring the Sidebar. Use when the user selects the AgentHall plugin, asks to save, update, or upload the current task to AgentHall, enters or pastes an AgentHall invitation code or link, clicks its conversation entry, asks to open AgentHall, view collaborators or Inbox, receive a Handoff, or send the current Agent output through AgentHall.
---

# Open AgentHall

Use the AgentHall MCP tools directly. Do not search the web, repository, logs, or local files to discover AgentHall.

## Save the current Codex task

When the user affirmatively says **保存到 AgentHall**, **更新到 AgentHall**, or **上传到 AgentHall** in the task they want to preserve:

1. Call `agenthall_context_save_current` exactly once with no arguments. Do not open the Sidebar, ask for confirmation, or require a ticket, terminal, project choice, or manual refresh.
2. The Tool uses Codex's private request metadata to select the exact current native task. Never supply, infer, repair, or substitute a task ID from the title, recent-task order, current project, working directory, Sidebar list, or conversation history.
3. On the first save, preserve this native task as a separate AgentHall task even when an unrelated cloud task has the same display name. On later saves, update the exact previously bound AgentHall task and append one child checkpoint.
4. Report success only when the returned operation has `status: succeeded` and `progress: 100`. A start/running snapshot is not success. On failure, report the stable error category and its single retry action without claiming that the cloud task was updated.
5. Treat normal case, whitespace, and trailing punctuation variations as the same affirmative intent. A question such as “能保存到 AgentHall 吗？” or quoted/example text containing the phrase is not authorization to save.
6. This is an explicit one-shot save, not background synchronization. Do not repeat the Tool call after an ambiguous response; its durable LocalOperation owns safe retry and idempotency.

## Open the interface

When the user selects AgentHall or asks to open it:

1. For collaborators, Inbox, Outbox, send, and receive tasks, call the matching AgentHall MCP tool so Codex renders the interactive Sidebar Widget in the current task. Use `agenthall_list_connections` to open the default AgentHall surface and `agenthall_list_inbox` when the user asks for Inbox or a pending file.
2. Do not ask the user to type an activation phrase. The Sidebar Widget is the primary installed-plugin surface because it can call the local Connector and return a verified attachment to the current Agent task.
3. Open the Sidebar first. When the host supports its private App-only authentication Tool, email registration and sign-in remain inside the Sidebar. When that private Tool cannot run, the Sidebar calls the public App-accessible `agenthall_pair` Tool and opens the official approval URL in the Codex in-app browser; the user completes email verification and current-Agent approval there, then returns to the Sidebar and clicks **我已完成登录**. Prefer claiming an existing AgentHall tab over opening a duplicate.
4. Web Inbox cannot access a local Connector or current Agent conversation. Never imply that its status rows can load a file locally; open the plugin Inbox instead.
5. If authentication is required for a normal Agent operation, open the Sidebar. Let the Sidebar use its in-place email flow or the public App-accessible browser pairing. A local profile file is not proof of authorization: Pairing validates it through AgentHall and replaces it only after a new Web approval when the server returns `AUTH_REQUIRED` or `CONNECTOR_REVOKED`. Never request an email OTP in chat and never ask the user to run pairing from the terminal.
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

## Continue a cloud checkpoint in Codex

When the user explicitly clicks **在本机继续**, the Sidebar sends a follow-up whose first line is exactly `AgentHall continuation ticket: <ticket>`. That one click is the user's explicit request to create one local Codex task. Complete the host continuation without asking the user to send another message, restart Codex, refresh the task list, choose a directory, or move the task manually.

1. Extract only the exact ticket from that first line and call `agenthall_context_host_claim`. Never repair, guess, reuse, search for, or substitute another ticket.
2. If the claim status is `already_claimed` or `attached`, stop. **Do not create a second task.** The existing host flow or LocalOperation owns the ticket.
3. Only when the claim status is `ready_to_create`, call `codex_app__list_projects`. Ignore the host-default home workspace: a project whose only root is the current user's home directory and whose name is that directory's basename is product-semantic projectless, not a user-created business project. If `projectName` is not `独立任务` and exactly one remaining local project has that exact display name, choose `destination_kind: "named_project"` and that project ID. If there is no exact remaining match, choose `destination_kind: "projectless"`. If more than one remaining project has the exact name, stop as ambiguous without creating a task. Never fall back to the current or selected project, a machine/user/home name, an unrelated directory, or list position.
4. Call `codex_app__create_thread` exactly once with the claim's task name as the title and `environment: { type: "local" }`. For `destination_kind: "named_project"`, use the selected project ID and set `target.type` to `project`. For `destination_kind: "projectless"`, omit every project ID and set `target.type` to `projectless`. Use a short initial prompt saying AgentHall is preparing the saved context and that the task must not modify files before the next injected turn. Never use a worktree for this continuation.
5. Use `wait_threads` with the exact thread and host returned by `codex_app__create_thread` until its initial turn is no longer running. Do not infer completion from elapsed time and do not create a replacement if waiting times out or is interrupted.
6. Call `agenthall_context_host_attach` once with the original ticket, the exact thread ID returned by `codex_app__create_thread`, and the exact `destination_kind` selected in step 3. Never use a title match, list position, guessed ID, another task ID, or an ID from conversation history.
7. The attach Tool starts or recovers the single AgentHall LocalOperation and returns one `hostWriterAction`. Call `codex_app__send_message_to_thread` exactly once with the exact thread and host returned by `codex_app__create_thread` and the exact `hostWriterAction.prompt`; do not summarize, edit, reveal, or reuse that prompt. This is the only Context injection turn and must stay on the original host writer.
8. Use `wait_threads` again with that exact thread and host until the host-writer Context turn is no longer running. Do not infer completion from elapsed time, do not call a Connector App Server `thread/resume` or `turn/start`, and do not create a replacement task if waiting times out or is interrupted.
9. After that exact turn completes, call `agenthall_context_host_complete` once with the original ticket and exact thread ID. This Tool performs read-only turn verification, records the local Binding, and settles the same LocalOperation. Do not call it before terminal completion and never substitute a title match or another ID.
10. Do not call the legacy `agenthall_context_continue` Tool, do not acknowledge the Operation, and do not navigate or restart Codex; the Sidebar owns progress polling, opening the completed task, and the final receipt.

## Preserve safety boundaries

- Treat the component as a UI for the versioned AgentHall MCP tool contract, not as an independent API client.
- Use `agenthall_connection_directory` for the current account's permanent ID/invitation or an exact full-email lookup. Never turn email lookup into fuzzy search.
- Creating a relationship requires a 1–50 character greeting. Use `agenthall_request_connection`; the result is pending, not connected.
- Incoming pending requests may be approved with `agenthall_approve_connection`. Rejecting a request or removing an active relationship uses destructive `agenthall_delete_connection`; never call it without the user's explicit action.
- A pending relationship cannot receive a Handoff. If a connection result says `connection_pending` or `mustStop`, stop before preparing or sending.
- Never infer a recipient when multiple contacts match. Ask only when the user is actually sending something.
- Preparing a Handoff never sends it. Send only after the user confirms the exact preview with the secure button or exact phrase `发送`.
- In the Sidebar Inbox, one explicit **加载到 Agent** click authorizes verified download and read-only loading into the current task. Do not ask for a second confirmation and never load without that click.
- When `agenthall_list_inbox` opens its Widget, the Inbox list is the first actionable screen. Do not ask the user to click a second launcher or open another surface before choosing **加载到 Agent**.
- Keep credentials, private keys, absolute quarantine paths, and attachment contents out of the component.
- Call the surface an AgentHall Sidebar Widget rendered by the plugin in the current Codex task; do not claim it is a native desktop sidebar. The Sidebar remains the starting and returning surface; account management, invitation continuation, and the host-compatibility authorization fallback may use the Codex in-app browser.

## Resolve recipient language semantically

- A recipient expression can be a relationship, alias, abbreviation, or natural-language equivalent of the user's private note. Do not require literal text equality; for example, `老婆` can match a private note such as `媳妇儿`.
- Call `agenthall_list_connections` with `detail: contacts` and the expression as `query`. The Connector resolves exact text and high-confidence relationship equivalents such as `老婆` and `媳妇儿`; do not ignore a unique returned result merely because other collaborators exist.
- Only when the result action is `resolve_semantically` should the Agent compare the returned nicknames and private notes for more open-ended semantic equivalence.
- Proceed with `agenthall_prepare_handoff` only when exactly one semantic match is clear, and pass that candidate's exact nickname. If none or multiple are plausible, show only plausible candidates and ask the user to choose.
- Never use local files, conversation history, project history, logs, APIs, Inbox, or the web to infer a recipient.
