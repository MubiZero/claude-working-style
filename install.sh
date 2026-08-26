#!/usr/bin/env bash
# Ставит WORKING-STYLE.md в ~/.claude, подключает его к ~/.claude/CLAUDE.md
# и вешает SubagentStart-хук, чтобы правила доезжали и до субагентов.
# Идемпотентно: можно запускать сколько угодно раз.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SOURCE="${REPO_DIR}/WORKING-STYLE.md"
TARGET="${CLAUDE_DIR}/WORKING-STYLE.md"
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
INCLUDE_LINE="@WORKING-STYLE.md"
HOOK_SOURCE="${REPO_DIR}/hooks/inject-working-style.sh"
HOOK_TARGET="${CLAUDE_DIR}/hooks/inject-working-style.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"

mkdir -p "${CLAUDE_DIR}"

# Симлинк на файл из репозитория — git pull сразу обновляет правила.
ln -sf "${SOURCE}" "${TARGET}"
echo "✓ symlink: ${TARGET} -> ${SOURCE}"

# Подключаем к глобальному CLAUDE.md (создаём файл, если его нет).
touch "${CLAUDE_MD}"
if grep -qxF "${INCLUDE_LINE}" "${CLAUDE_MD}"; then
  echo "✓ ${CLAUDE_MD} уже подключает ${INCLUDE_LINE}"
else
  printf '%s\n' "${INCLUDE_LINE}" >> "${CLAUDE_MD}"
  echo "✓ дописал ${INCLUDE_LINE} в ${CLAUDE_MD}"
fi

# Субагенты не получают CLAUDE.md, поэтому правила подаются им хуком
# SubagentStart -> additionalContext.
mkdir -p "${CLAUDE_DIR}/hooks"
chmod +x "${HOOK_SOURCE}"
ln -sfn "${HOOK_SOURCE}" "${HOOK_TARGET}"
echo "✓ symlink: ${HOOK_TARGET} -> ${HOOK_SOURCE}"

[ -f "${SETTINGS}" ] || printf '{}\n' > "${SETTINGS}"
python3 - "${SETTINGS}" <<'PY'
import collections, json, sys

path = sys.argv[1]
settings = json.load(open(path, encoding="utf-8"), object_pairs_hook=collections.OrderedDict)

command = "$HOME/.claude/hooks/inject-working-style.sh"
groups = settings.setdefault("hooks", collections.OrderedDict()).setdefault("SubagentStart", [])

if any("inject-working-style" in h.get("command", "") for g in groups for h in g.get("hooks", [])):
    print("\u2713 SubagentStart-хук уже прописан в settings.json")
else:
    groups.append({"hooks": [{
        "type": "command",
        "command": command,
        "timeout": 10,
        "statusMessage": "Загружаю working style",
    }]})
    with open(path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("\u2713 добавил SubagentStart-хук в settings.json")
PY

echo "Готово. Новые сессии и субагенты подхватят правила после перезапуска Claude Code."
