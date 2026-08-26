#!/usr/bin/env bash
# SubagentStart hook: кладёт WORKING-STYLE.md в контекст каждого субагента.
# Главные сессии получают файл через ~/.claude/CLAUDE.md (@WORKING-STYLE.md),
# субагенты — нет, поэтому им он подаётся здесь.
set -euo pipefail

STYLE="${HOME}/.claude/WORKING-STYLE.md"
[ -r "$STYLE" ] || exit 0

python3 - "$STYLE" <<'PY'
import json, sys

body = open(sys.argv[1], encoding="utf-8").read()
header = (
    "Рабочий стиль пользователя — действует и на субагентов.\n"
    "Приоритет при конфликте: инструкция в самой задаче → CLAUDE.md проекта → эти правила.\n\n"
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SubagentStart",
        "additionalContext": header + body,
    },
    "suppressOutput": True,
}, ensure_ascii=False))
PY
