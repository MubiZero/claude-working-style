# Working Style

Как ИИ-агент работает со мной: коротко по-русски, проверено до «готово», объём — дешёвым агентам.

## Установка

Claude Code (на любом устройстве):

```bash
claude plugin marketplace add MubiZero/claude-working-style && claude plugin install working-style@mubizero-working-style
```

Codex, Gemini CLI и другие ИИ, которые читают `AGENTS.md`:

```bash
git clone https://github.com/MubiZero/claude-working-style ~/claude-working-style && ~/claude-working-style/install.sh
```

## Что внутри

| Часть | Где | Когда действует |
|---|---|---|
| Ядро правил | `core.md` | в каждой сессии и у каждого субагента (хук `SessionStart` / `SubagentStart`, ~100 токенов) |
| Полные правила и кейсы | скилл `working-style` | подгружаются, когда задача их касается |
| Стиль ответов «Кратко» | `output-styles/kratko.md` | всегда, пока плагин включён (`force-for-plugin`) |
| Ход не кончается объявлением | хук `Stop` | шаг «дальше беру X» без начала — ход не закрывается |
| Длинный ответ | хук `Stop` + `UserPromptSubmit` | напоминание «2–3 строки» перед следующим ответом |
| Другие ИИ | `AGENTS.md` | `install.sh` кладёт его в `~/.codex/AGENTS.md` и `~/.gemini/GEMINI.md` |

Личное (стек, секреты, терминал) в плагин не входит: это `~/.claude/CLAUDE.md` и локальные скиллы.

Правка правил — только в `core.md` и `skills/working-style/`; `AGENTS.md` собирается из `core.md` (`install.sh`).
