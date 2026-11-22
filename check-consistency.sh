#!/usr/bin/env bash
# Проверка согласованности правил: падает, если ядро, стиль, манифесты или хуки снова расходятся.
#   ./check-consistency.sh        — проверить
#   ./check-consistency.sh sync   — скопировать блок маршрутизации из core.md в стиль и пересобрать AGENTS.md + rules/AGENTS.md
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

block() { sed -n '/<!-- routing:start -->/,/<!-- routing:end -->/p' "$1"; }
fail=0
bad() { echo "✗ $1"; fail=1; }

if [ "${1:-}" = "sync" ]; then
  new="$(block core.md)"
  [ -n "$new" ] || { echo "в core.md нет блока routing"; exit 1; }
  CORE_BLOCK="$new" perl -0pi -e 'BEGIN{$b=$ENV{CORE_BLOCK}} s/<!-- routing:start -->.*?<!-- routing:end -->/$b/s' output-styles/kratko.md
  mkdir -p rules
  { printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
    cat core.md; } > rules/AGENTS.md
  { printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
    sed 's#skill `working-style`#file skills/working-style/WORKING-STYLE.md next to this#' core.md; } > AGENTS.md
  echo "✓ маршрутизация скопирована в стиль, AGENTS.md и rules/AGENTS.md пересобраны"
fi

# 1. Блок маршрутизации в ядре и в стиле одинаковый.
[ "$(block core.md)" = "$(block output-styles/kratko.md)" ] || bad "блок routing в core.md и kratko.md разошёлся (./check-consistency.sh sync)"

# 2. Запрещённые формулы: просьба спрашивать вариантами текстом.
if rg -n "вариантами «1\)|вариантами 1/2/3|варианты 1/2/3" core.md output-styles hooks AGENTS.md rules/AGENTS.md >/dev/null 2>&1; then
  rg -n "вариантами «1\)|вариантами 1/2/3|варианты 1/2/3" core.md output-styles hooks AGENTS.md rules/AGENTS.md || true
  bad "правило велит спрашивать вариантами текстом; вопрос — только AskUserQuestion / ask_question"
fi

# 3. AGENTS.md и rules/AGENTS.md собраны из актуального core.md.
expected="$(printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'; sed 's#skill `working-style`#file skills/working-style/WORKING-STYLE.md next to this#' core.md)"
[ "$expected" = "$(cat AGENTS.md)" ] || bad "AGENTS.md не равен сборке из core.md (./check-consistency.sh sync)"
expected_rules="$(printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'; cat core.md)"
[ -f rules/AGENTS.md ] && [ "$expected_rules" = "$(cat rules/AGENTS.md)" ] || bad "rules/AGENTS.md не равен сборке из core.md (./check-consistency.sh sync)"

# 3b. Версии plugin.json и .claude-plugin/plugin.json совпадают.
v1="$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')"
v2="$(python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json"))["version"])')"
[ "$v1" = "$v2" ] || bad "версии plugin.json ($v1) и .claude-plugin/plugin.json ($v2) расходятся"

# 4. Хук ловит текстовые варианты и объявления в форматах Claude Code и Antigravity.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.claude/hooks"

run_claude() { # $1 = текст ответа; печатает код выхода хука
  python3 - "$1" "$tmp/t.jsonl" <<'PY'
import json, sys
text, path = sys.argv[1], sys.argv[2]
with open(path, "w") as f:
    f.write(json.dumps({"type": "user", "message": {"content": "привет"}}) + "\n")
    f.write(json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}) + "\n")
PY
  HOME="$tmp" python3 hooks/announce-guard.py <<<"{\"transcript_path\":\"$tmp/t.jsonl\",\"session_id\":\"s1\"}" >/dev/null 2>&1 && echo 0 || echo $?
}

run_agy() { # $1 = текст ответа; печатает decision из stdout JSON
  python3 - "$1" "$tmp/agy.jsonl" <<'PY'
import json, sys
text, path = sys.argv[1], sys.argv[2]
with open(path, "w") as f:
    f.write(json.dumps({"type": "USER_INPUT", "content": "привет"}) + "\n")
    f.write(json.dumps({"type": "PLANNER_RESPONSE", "content": text}) + "\n")
PY
  HOME="$tmp" python3 hooks/announce-guard.py <<<"{\"transcriptPath\":\"$tmp/agy.jsonl\",\"conversationId\":\"c1\",\"terminationReason\":\"NO_TOOL_CALL\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("decision",""))'
}

[ "$(run_claude $'Что делаем дальше? 1) окно киоска 2) экран игрока')" = 2 ] || bad "Claude-хук не поймал «1) … 2) …»"
[ "$(run_claude $'Что делаем дальше?\n1) окно киоска\n2) экран игрока')" = 2 ] || bad "Claude-хук не поймал список вариантов"
[ "$(run_claude $'Сделай:\n1. Открой Панель\n2. Нажми «Старт»')" = 0 ] || bad "Claude-хук ложно сработал на инструкцию"
[ "$(run_claude 'Готово, тесты не гонял. Запушить?')" = 0 ] || bad "Claude-хук ложно сработал на обычный вопрос"

[ "$(run_agy $'Что делаем дальше? 1) окно киоска 2) экран игрока')" = "continue" ] || bad "AGY-хук не поймал «1) … 2) …»"
[ "$(run_agy $'Готово. Дальше беру склад.')" = "continue" ] || bad "AGY-хук не поймал объявление следующего шага"
[ "$(run_agy 'Готово, тесты не гонял. Запушить?')" = "allow" ] || bad "AGY-хук ложно сработал на обычный вопрос"

# 5. R1 stale-verification guard: правка после теста без новой проверки блокирует «Готово», если не сказано «тесты не гонял».
python3 - "$tmp/stale.jsonl" <<'PY'
import json, sys
with open(sys.argv[1], "w") as f:
    f.write(json.dumps({"type": "USER_INPUT", "content": "почини баг"}) + "\n")
    f.write(json.dumps({"type": "PLANNER_RESPONSE", "content": "", "tool_calls": [{"name": "run_command"}]}) + "\n")
    f.write(json.dumps({"type": "PLANNER_RESPONSE", "content": "Готово, починил баг.", "tool_calls": [{"name": "edit_file"}]}) + "\n")
PY
stale_res="$(HOME="$tmp" python3 hooks/announce-guard.py <<<"{\"transcriptPath\":\"$tmp/stale.jsonl\",\"conversationId\":\"c2\",\"terminationReason\":\"NO_TOOL_CALL\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("decision",""))')"
[ "$stale_res" = "continue" ] || bad "R1-хук не поймал «Готово» после правки без повторной проверки"

python3 - "$tmp/honest.jsonl" <<'PY'
import json, sys
with open(sys.argv[1], "w") as f:
    f.write(json.dumps({"type": "USER_INPUT", "content": "почини баг"}) + "\n")
    f.write(json.dumps({"type": "PLANNER_RESPONSE", "content": "Готово, тесты не гонял.", "tool_calls": [{"name": "edit_file"}]}) + "\n")
PY
honest_res="$(HOME="$tmp" python3 hooks/announce-guard.py <<<"{\"transcriptPath\":\"$tmp/honest.jsonl\",\"conversationId\":\"c3\",\"terminationReason\":\"NO_TOOL_CALL\"}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("decision",""))')"
[ "$honest_res" = "allow" ] || bad "R1-хук ложно заблокировал честное «тесты не гонял»"

# 6. Anti-slop линтер прозы (prose_check.py) на эталонных фикстурах.
python3 skills/working-style/scripts/prose_check.py skills/working-style/evals/good_clean.md >/dev/null || bad "prose_check упал на чистом тексте"
if python3 skills/working-style/scripts/prose_check.py skills/working-style/evals/bad_slop.md >/dev/null 2>&1; then
  bad "prose_check пропустил нейрослоп в bad_slop.md"
fi

[ "$fail" = 0 ] && echo "✓ правила, R1-страж, anti-slop линтер и хуки (Claude + Antigravity) согласованы" || exit 1
