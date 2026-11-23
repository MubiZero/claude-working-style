# Working Style

Универсальный набор правил, скилла и хуков для любых ИИ-агентов (Antigravity, Claude Code, Codex, Cursor, Gemini CLI и любых инструментов с `AGENTS.md`): коротко по-русски, проверка после последней правки, оркестратор планирует и проверяет, а код пишут дешёвые исполнители.

## Установка

Универсальный установщик (Antigravity, Codex и общий стандарт `~/.agents/skills`):

```bash
git clone https://github.com/MubiZero/working-style ~/projects/working-style && bash ~/projects/working-style/install.sh
```

Claude Code (на любом устройстве):

```bash
claude plugin marketplace add MubiZero/working-style && claude plugin install working-style@mubizero-working-style
```

Любой агент с `AGENTS.md`: добавь симлинк или копию `AGENTS.md` из корня репозитория.

## Что внутри

| Часть | Где | Когда действует |
|---|---|---|
| Ядро правил | `core.md`, `AGENTS.md`, `rules/AGENTS.md` | в каждой сессии и у каждого субагента |
| Полные правила и кейсы | скилл `skills/working-style/` | подгружается по требованию |
| Стиль ответов «Кратко» | `output-styles/kratko.md` | режим кратких ответов (для сред с output-styles) |
| Хуки контроля ответа и R1 | `hooks/announce-guard.py`, `hooks/length-note.py` | форматы Antigravity и Claude Code; состояние в `$PLUGIN_DATA` или `~/.local/state/working-style` |
| Инжектор контекста | `hooks/inject-working-style.sh` | JSON для Claude Code или обычный текст (`plain`) |

Правка правил делается только в `core.md` и `skills/working-style/`; `AGENTS.md` и `rules/AGENTS.md` собираются автоматически скриптом `install.sh` или `./check-consistency.sh sync`.

Проверка согласованности (блок маршрутизации в ядре и стиле, запрещённые формулы, `AGENTS.md`, R1-страж, anti-slop линтер и тесты хуков): `./check-consistency.sh`.
