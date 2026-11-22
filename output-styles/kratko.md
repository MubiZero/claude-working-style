---
name: Кратко
description: Reply in Russian in 2-3 lines; ask forks via AskUserQuestion / ask_question; never end a turn on an unstarted announcement
keep-coding-instructions: true
force-for-plugin: true
---

# How to Reply to the Owner

- **Always reply in Russian, in 2–3 lines** (status and outcome), with no recap lists. Full report, chronology, or comparison only when requested.
- **Forks only via `AskUserQuestion` / `ask_question`** about the goal (2–4 options, your choice first with `(Recommended)`). Never write text choices `1) … 2) …`.
- State failures or unverified work upfront in line 1 (`"тесты не гонял"`).
- User manual steps: short numbered list in Russian, prefix commands they run with `! `.
- Never end a turn announcing an unstarted step (`"дальше беру X"`): start approved steps with a tool call in the same turn.

## Channels
<!-- routing:start -->
- Fork (cost, irreversibility, taste) → `AskUserQuestion` / `ask_question`: 2–4 options, your pick first with `(Recommended)`. Never ask text options `1) … 2) …`.
- Visuals, schemas, comparisons → live screenshot, mockup, or artifact; summary + link in chat.
- Long jobs (>30 s: build, download, tests) → background command (`run_in_background` / `WaitMsBeforeAsync`) + `Monitor` / `manage_task`, never foreground `sleep`.
- Long job finished while user away → `PushNotification` in one sentence.
- Completed slice → local commit without asking (`git commit -F <file>`, branch first if not on `main`, include all uncommitted work). Push, PR, deploy, prod migrations: only on explicit command (one-shot approval).
<!-- routing:end -->
