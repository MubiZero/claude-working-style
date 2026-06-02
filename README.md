# claude-working-style

Мой персональный рабочий стиль для Claude Code — правила общения, ведения планов,
автономности, чистоты кода и памяти. Приватный, подтягивается на любой машине.

## Что внутри
- **`WORKING-STYLE.md`** — сами правила (применяются во всех проектах).
- **`install.sh`** — ставит файл в `~/.claude/` и подключает его к `~/.claude/CLAUDE.md`.

## Установка на новой машине
```bash
git clone git@github.com:MubiZero/claude-working-style.git ~/claude-working-style
cd ~/claude-working-style
./install.sh
```

`install.sh` делает симлинк `~/.claude/WORKING-STYLE.md → этот репозиторий` и дописывает строку
`@WORKING-STYLE.md` в `~/.claude/CLAUDE.md`, если её там ещё нет. Поскольку это симлинк —
`git pull` в этой папке сразу обновляет правила во всех проектах.

## Обновить правила
```bash
cd ~/claude-working-style
git pull
```
Или отредактировать `WORKING-STYLE.md`, затем `git commit` + `git push`.
