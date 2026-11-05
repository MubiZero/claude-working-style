#!/usr/bin/env bash
# For AIs other than Claude Code (Codex, Gemini CLI, Cursor…): builds AGENTS.md from core.md and links it where they
# read their global instructions. Claude Code takes the plugin instead (README). Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

{
  printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
  # The core names Claude Code tools (skills, worktrees); for other AIs the full rules are a file.
  sed 's#скилл `working-style`#файл skills/working-style/WORKING-STYLE.md рядом с этим#' "$REPO/core.md"
} > "$REPO/AGENTS.md"
echo "✓ $REPO/AGENTS.md"

link() {
  mkdir -p "$(dirname "$1")"
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "• $1 уже есть и не ссылка — не трогаю (добавьте в него строку: см. $REPO/AGENTS.md)"
    return
  fi
  ln -sf "$REPO/AGENTS.md" "$1"
  echo "✓ $1 -> AGENTS.md"
}

link "$HOME/.codex/AGENTS.md"
link "$HOME/.gemini/GEMINI.md"
