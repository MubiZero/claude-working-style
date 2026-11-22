#!/usr/bin/env bash
# Builds AGENTS.md and rules/AGENTS.md from core.md, links ~/.codex/AGENTS.md, and links the plugin into
# Antigravity (~/.gemini/config/plugins/working-style). Removes legacy ~/.gemini/GEMINI.md symlink if it
# pointed here so Antigravity does not load the core rules twice. Idempotent.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$REPO/rules"
{
  printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
  cat "$REPO/core.md"
} > "$REPO/rules/AGENTS.md"
echo "✓ $REPO/rules/AGENTS.md"

{
  printf '%s\n\n' '<!-- Generated from core.md by install.sh; edit core.md. -->'
  # For standalone AGENTS.md readers without skills, point at the file next to it.
  sed 's#скилл `working-style`#файл skills/working-style/WORKING-STYLE.md рядом с этим#' "$REPO/core.md"
} > "$REPO/AGENTS.md"
echo "✓ $REPO/AGENTS.md"

link() {
  mkdir -p "$(dirname "$1")"
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "• $1 уже есть и не ссылка — не трогаю (добавьте в него строку: см. $REPO/AGENTS.md)"
    return
  fi
  ln -sf "$2" "$1"
  echo "✓ $1 -> $2"
}

link "$HOME/.codex/AGENTS.md" "$REPO/AGENTS.md"

# Antigravity loads rules/AGENTS.md, skills/working-style, and hooks.json directly from the plugin.
if [ -L "$HOME/.gemini/GEMINI.md" ] && [ "$(readlink "$HOME/.gemini/GEMINI.md")" = "$REPO/AGENTS.md" ]; then
  rm -f "$HOME/.gemini/GEMINI.md"
  echo "✓ удалён дублирующий симлинк $HOME/.gemini/GEMINI.md (правила теперь идут из плагина working-style)"
fi

mkdir -p "$HOME/.gemini/config/plugins"
ln -sfn "$REPO" "$HOME/.gemini/config/plugins/working-style"
echo "✓ $HOME/.gemini/config/plugins/working-style -> $REPO"
