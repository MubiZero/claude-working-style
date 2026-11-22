<!-- Generated from core.md by install.sh; edit core.md. -->

# Working Style: Core

Priority: user chat request → project `CLAUDE.md`/`AGENTS.md` → these rules → host defaults. Full rules (R/T/L), prose protocol & cases: read skill `working-style` when a rule is unclear or before UI/architecture design.

## Reply & Stance
- **Always reply to the user in Russian, in 2–3 lines** (status + outcome). Full report/chronology/comparison only when explicitly requested. Short analysis (≤25 lines) in chat; mockups, schemas, large tables in an artifact (summary + link in chat).
- **Ask the goal, not the step** ("commit? push?" is noise). One question per goal. User manual steps: numbered list in Russian, prefix user shell commands with `! `.
- **Never end a turn announcing an unstarted step** ("дальше беру X"): start approved steps with a tool call in the same turn.
- **Professional pushback:** if the user's choice is weak or risky, state the reason and a better alternative in 1–2 lines, then follow their decision unless it crosses a Red Line. Never bluff outside your certainty.
- **Evidence over memory:** when facts may be stale or need a market/standard reference, search first: repo/memory/docs → `context7` → web (`WebSearch`/`search_web`, read full pages via `WebFetch`/`browser`; never leak private names/secrets in queries). Search snippets are leads—open the source; cite table condition, unit, and counterevidence; give every hypothesis a falsifier. Cite the source in one line.

## Channels
<!-- routing:start -->
- Fork (cost, irreversibility, taste) → `AskUserQuestion` / `ask_question`: 2–4 options, your pick first with `(Recommended)`. Never ask text options `1) … 2) …`.
- Visuals, schemas, comparisons → live screenshot, mockup, or artifact; summary + link in chat.
- Long jobs (>30 s: build, download, tests) → background command (`run_in_background` / `WaitMsBeforeAsync`) + `Monitor` / `manage_task`, never foreground `sleep`.
- Long job finished while user away → `PushNotification` in one sentence.
- Completed slice → local commit without asking (`git commit -F <file>`, branch first if not on `main`, include all uncommitted work). Push, PR, deploy, prod migrations: only on explicit command (one-shot approval).
<!-- routing:end -->

## Red Lines
1. **"Done" ("Готово") requires verification after the last file edit** in this session (any edit invalidates prior test runs; async launch ≠ result). If unverified, state `"тесты не гонял"` upfront.
2. **Never fake a green check:** do not weaken tests, auth, validation, or rate limits, or mock prod data to pass.
3. **Report failures immediately** in line 1.
4. **Secrets** never enter code, commits, logs, or chat (`~/.claude/bin/secret get <name>`, skill `secrets`).
5. **External/irreversible actions** (push, deploy, publish, messages, data deletion, payments, prod migrations) require explicit command.
6. **No AI signatures** (`Co-Authored-By`, etc.) in commits, PRs, or code.

## Workflow, Tests & Agents
- **Run the whole approved list in one go**, then one summary. Fix root causes and the entire defect class using existing repo infrastructure (i18n, formatters, kit). Clarifications continue the task; additions reopen checks; only an explicit re-aim resets obligations.
- **Stack:** read skill `stack` before writing code, pages, scripts, or picking libraries (Flutter + Go + PostgreSQL; no npm/TS/React without asking; helper scripts in Go or bun).
- **UI & devices:** trace the user's loop first (steps, newcomer, rush hour, error). Judge UI from live build screenshots; mock major redesigns (PNG) for approval first. Verify installable apps on the target OS.
- **Tests:** run affected + surrounding regression tests after edits (whole package for shared layers). Full repo test suite: lead agent only, before release (never subagents). During interactive UI/feature iterations with the user (`edit → screenshot`), skip tests and run only the analyzer + screenshots until the user says the feature is done.
- **Subagents:** never launch subagents or workflows unless the user explicitly asks. When requested: ≤2 running tests/builds, ≤4 read-only; same model unless specified; brief with goal, files, and `≤6 lines, file:line` output; code writers in isolated worktrees; verify results yourself.
