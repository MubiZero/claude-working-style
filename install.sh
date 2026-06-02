#!/usr/bin/env bash
# Ставит WORKING-STYLE.md в ~/.claude и подключает его к ~/.claude/CLAUDE.md.
# Идемпотентно: можно запускать сколько угодно раз.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
SOURCE="${REPO_DIR}/WORKING-STYLE.md"
TARGET="${CLAUDE_DIR}/WORKING-STYLE.md"
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
INCLUDE_LINE="@WORKING-STYLE.md"

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

echo "Готово."
