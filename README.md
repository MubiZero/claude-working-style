# claude-working-style

Мой персональный рабочий стиль для Claude Code — правила общения, ведения планов,
автономности, чистоты кода и памяти. Приватный, подтягивается на любой машине.

## Что внутри
- **`WORKING-STYLE.md`** — сами правила (применяются во всех проектах).
- **`hooks/inject-working-style.sh`** — `SubagentStart`-хук: подаёт правила субагентам.
- **`install.sh`** — ставит файл в `~/.claude/`, подключает его к `~/.claude/CLAUDE.md`
  и прописывает хук в `~/.claude/settings.json`.

## Как правила доезжают до агента
Два разных канала, потому что одного не хватает:

| Кто | Канал |
|---|---|
| Главная сессия Claude Code | `~/.claude/CLAUDE.md` → строка `@WORKING-STYLE.md` |
| Субагенты (Task / Agent tool) | хук `SubagentStart` → `hookSpecificOutput.additionalContext` |

Субагент стартует со своим системным промптом и глобальный `CLAUDE.md` не наследует —
поэтому для него правила кладёт хук. Файл при этом один и тот же, дублирования нет.

## Структура правил
Файл разбит на три слоя по убыванию жёсткости:

| Слой | Что это | Как применяется |
|---|---|---|
| **R** — красные линии | не обходятся никогда | конфликт с просьбой → агент говорит и ждёт подтверждения |
| **T** — правила с триггером | «когда X → делай Y» | триггер не сработал — правило молчит |
| **L** — линзы | способ думать, не чеклист | по смыслу задачи |

Приоритет при конфликте: прямая просьба в чате → `CLAUDE.md` проекта → R → T → L.

## Установка на новой машине
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
