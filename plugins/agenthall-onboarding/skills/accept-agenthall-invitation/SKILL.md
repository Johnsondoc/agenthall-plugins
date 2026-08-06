---
name: accept-agenthall-invitation
description: Continue an AgentHall invitation safely. Use when the user pastes an AgentHall invitation code or an exact https://agent-hall.com/i/... link, asks to accept an AgentHall invitation, or wants to register from an invitation.
---

# Accept an AgentHall invitation

Use `agenthall_open_invitation` with the exact invitation supplied by the user.

After the tool returns:

1. Present the returned official AgentHall invitation URL as the single next action.
2. Explain that registration or sign-in and invitation acceptance continue in the browser.
3. Never ask for, read, repeat, or store an email verification code in the conversation.
4. Never claim the invitation has been accepted until the user completes the Web flow.
5. If validation fails, say the invitation format or origin is invalid. Do not repair, guess, search for, or substitute another invitation.

This public Onboarding plugin does not read local files, list contacts, send files, receive files, or install the AgentHall Companion silently. If the user later wants file collaboration, explain that the separate local AgentHall Companion requires its own explicit installation and per-send confirmation.
