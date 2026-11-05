#!/usr/bin/env bash
# SessionStart/SubagentStart hook: кладёт ядро правил (core.md) в контекст.
# Один скрипт на оба события — имя события приходит первым аргументом.
set -euo pipefail

EVENT="${1:?usage: inject-working-style.sh <SessionStart|SubagentStart>}"
STYLE="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/core.md"
[ -r "$STYLE" ] || exit 0

# Only the short core goes in every session and subagent; the full rules are the working-style skill, read on demand.

python3 - "$STYLE" "$EVENT" <<'PY'
import json, sys

path, event = sys.argv[1], sys.argv[2]
body = open(path, encoding="utf-8").read()
header = (
    "Рабочий стиль пользователя — действует и на субагентов.\n"
    "Приоритет при конфликте: инструкция в самой задаче → CLAUDE.md проекта → эти правила.\n\n"
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": event,
        "additionalContext": header + body,
    },
    "suppressOutput": True,
}))
PY
