# claude-working-style

Мой персональный рабочий стиль для Claude Code — правила общения, ведения планов,
автономности, чистоты кода и памяти. Приватный, подтягивается на любой машине.

## Что внутри
- **`WORKING-STYLE.md`** — сами правила (применяются во всех проектах).
- **`.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`** — репозиторий одновременно
  marketplace и плагин, ставится через `/plugin install`.
- **`hooks/hooks.json`, `hooks/inject-working-style.sh`** — `SessionStart`/`SubagentStart`-хук:
  подаёт правила и главной сессии, и субагентам.
- **`install.sh`** — альтернатива без marketplace: симлинк файла в `~/.claude/` и строка
  в `~/.claude/CLAUDE.md`.

## Как правила доезжают до агента
Способ зависит от установки:

| Кто | Установка через плагин | Ручная установка (`install.sh`) |
|---|---|---|
| Главная сессия Claude Code | хук `SessionStart` → `hookSpecificOutput.additionalContext` | `~/.claude/CLAUDE.md` → строка `@WORKING-STYLE.md` |
| Субагенты (Task / Agent tool) | хук `SubagentStart` → `hookSpecificOutput.additionalContext` | хук `SubagentStart` (симлинк в `~/.claude/hooks/`) |

Субагент стартует со своим системным промптом и глобальный `CLAUDE.md` не наследует —
поэтому для него правила всегда кладёт хук. Файл при этом один и тот же, дублирования нет.

## Структура правил
Файл разбит на три слоя по убыванию жёсткости:

| Слой | Что это | Как применяется |
|---|---|---|
| **R** — красные линии | не обходятся никогда | конфликт с просьбой → агент говорит и ждёт подтверждения |
| **T** — правила с триггером | «когда X → делай Y» | триггер не сработал — правило молчит |
| **L** — линзы | способ думать, не чеклист | по смыслу задачи |

Приоритет при конфликте: прямая просьба в чате → `CLAUDE.md` проекта → R → T → L.

## Установка как плагин (рекомендуется)
Репозиторий сам себе marketplace — плагин лежит в корне.

```
/plugin marketplace add MubiZero/claude-working-style
/plugin install claude-working-style@claude-working-style
```

Плагин сам вешает `SessionStart` и `SubagentStart` хуки (`hooks/hooks.json`) — они кладут
`WORKING-STYLE.md` в контекст главной сессии и субагентов через `${CLAUDE_PLUGIN_ROOT}`.
`~/.claude/CLAUDE.md` и симлинки плагин не трогает.

Обновление: `/plugin marketplace update claude-working-style` (или переустановить плагин).

## Установка вручную (без marketplace)
```bash
gh repo clone MubiZero/claude-working-style ~/claude-working-style
cd ~/claude-working-style
./install.sh
```
(или `git clone https://github.com/MubiZero/claude-working-style.git ~/claude-working-style`)

`install.sh` делает симлинк `~/.claude/WORKING-STYLE.md → этот репозиторий` и дописывает строку
`@WORKING-STYLE.md` в `~/.claude/CLAUDE.md`, если её там ещё нет. Поскольку это симлинк —
`git pull` в этой папке сразу обновляет правила во всех проектах.

## Обновить правила
```bash
cd ~/claude-working-style
git pull
```
Или отредактировать `WORKING-STYLE.md`, затем `git commit` + `git push`.
