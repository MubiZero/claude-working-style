#!/usr/bin/env bash
# SessionStart/SubagentStart hook: кладёт ядро правил (core.md) в контекст любого поддерживаемого агента.
set -euo pipefail

EVENT="${1:-SessionStart}"
ROOT="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
STYLE="$ROOT/core.md"
[ -r "$STYLE" ] || exit 0

python3 - "$STYLE" "$EVENT" <<'PY'
import json, sys

path, event = sys.argv[1], sys.argv[2]
body = open(path, encoding="utf-8").read()
header = (
    "Рабочий стиль пользователя: действует на основной агент и на субагентов.\n"
    "Приоритет при конфликте: запрос пользователя в чате → инструкции проекта (AGENTS.md / GEMINI.md / CLAUDE.md) → эти правила.\n\n"
)

if event in ("plain", "generic"):
    print(header + body)
else:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": header + body,
        },
        "suppressOutput": True,
    }))
PY
