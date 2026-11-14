#!/usr/bin/env bash
# Проверка согласованности правил: падает, если ядро, стиль или хуки снова расходятся.
#   ./check-consistency.sh        — проверить
#   ./check-consistency.sh sync   — скопировать блок маршрутизации из core.md в стиль и пересобрать AGENTS.md
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

block() { sed -n '/<!-- routing:start -->/,/<!-- routing:end -->/p' "$1"; }
fail=0
bad() { echo "✗ $1"; fail=1; }

if [ "${1:-}" = "sync" ]; then
  new="$(block core.md)"
  [ -n "$new" ] || { echo "в core.md нет блока routing"; exit 1; }
  CORE_BLOCK="$new" perl -0pi -e 'BEGIN{$b=$ENV{CORE_BLOCK}} s/<!-- routing:start -->.*?<!-- routing:end -->/$b/s' output-styles/kratko.md
  { printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
    sed 's#скилл `working-style`#файл skills/working-style/WORKING-STYLE.md рядом с этим#' core.md; } > AGENTS.md
  echo "✓ маршрутизация скопирована в стиль, AGENTS.md пересобран"
fi

# 1. Блок маршрутизации в ядре и в стиле одинаковый.
[ "$(block core.md)" = "$(block output-styles/kratko.md)" ] || bad "блок routing в core.md и kratko.md разошёлся (./check-consistency.sh sync)"

# 2. Запрещённые формулы: просьба спрашивать вариантами текстом.
if rg -n "вариантами «1\)|вариантами 1/2/3|варианты 1/2/3" core.md output-styles hooks AGENTS.md >/dev/null 2>&1; then
  rg -n "вариантами «1\)|вариантами 1/2/3|варианты 1/2/3" core.md output-styles hooks AGENTS.md || true
  bad "правило велит спрашивать вариантами текстом; вопрос — только AskUserQuestion"
fi

# 3. AGENTS.md собран из актуального core.md.
expected="$(printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'; sed 's#скилл `working-style`#файл skills/working-style/WORKING-STYLE.md рядом с этим#' core.md)"
[ "$expected" = "$(cat AGENTS.md)" ] || bad "AGENTS.md не равен сборке из core.md (./check-consistency.sh sync)"

# 4. Хук ловит текстовые варианты и пропускает инструкцию и обычный вопрос.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
run() { # $1 = текст ответа; печатает код выхода хука
  python3 - "$1" "$tmp/t.jsonl" <<'PY'
import json, sys
text, path = sys.argv[1], sys.argv[2]
with open(path, "w") as f:
    f.write(json.dumps({"type": "user", "message": {"content": "привет"}}) + "\n")
    f.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}) + "\n")
PY
  HOME="$tmp" python3 hooks/announce-guard.py <<<"{\"transcript_path\":\"$tmp/t.jsonl\"}" >/dev/null 2>&1 && echo 0 || echo $?
}
mkdir -p "$tmp/.claude/hooks"
[ "$(run $'Что делаем дальше? 1) окно киоска 2) экран игрока')" = 2 ] || bad "хук не поймал «1) … 2) …»"
[ "$(run $'Что делаем дальше?\n1) окно киоска\n2) экран игрока')" = 2 ] || bad "хук не поймал список вариантов"
[ "$(run $'Сделай:\n1. Открой Панель\n2. Нажми «Старт»')" = 0 ] || bad "хук ложно сработал на инструкцию"
[ "$(run 'Готово, тесты не гонял. Запушить?')" = 0 ] || bad "хук ложно сработал на обычный вопрос"

[ "$fail" = 0 ] && echo "✓ правила согласованы" || exit 1
