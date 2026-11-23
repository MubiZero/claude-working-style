#!/usr/bin/env bash
# Собирает AGENTS.md и rules/AGENTS.md из core.md и подключает working-style ко всем поддерживаемым ИИ-средам.
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
  sed 's#skill `working-style`#file skills/working-style/WORKING-STYLE.md next to this#' "$REPO/core.md"
} > "$REPO/AGENTS.md"
echo "✓ $REPO/AGENTS.md"

link() {
  mkdir -p "$(dirname "$1")"
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "• $1 уже есть и не ссылка, не трогаю (подключи вручную: $2)"
    return
  fi
  ln -sfn "$2" "$1"
  echo "✓ $1 -> $2"
}

# 1. Codex CLI / универсальные читатели ~/.codex/AGENTS.md
link "$HOME/.codex/AGENTS.md" "$REPO/AGENTS.md"

# 2. Общий стандарт Agent Skills (Codex, Cursor, OpenCode и совместимые)
link "$HOME/.agents/skills/working-style" "$REPO/skills/working-style"

# 3. Antigravity: подключаем как плагин; убираем старый симлинк ~/.gemini/GEMINI.md, если он вёл в этот плагин
if [ -L "$HOME/.gemini/GEMINI.md" ]; then
  target="$(readlink "$HOME/.gemini/GEMINI.md" || true)"
  if [ "$target" = "$REPO/AGENTS.md" ] || [ "$target" = "$HOME/claude-working-style/AGENTS.md" ]; then
    rm -f "$HOME/.gemini/GEMINI.md"
    echo "✓ удалён дублирующий симлинк $HOME/.gemini/GEMINI.md"
  fi
fi

mkdir -p "$HOME/.gemini/config/plugins"
ln -sfn "$REPO" "$HOME/.gemini/config/plugins/working-style"
echo "✓ $HOME/.gemini/config/plugins/working-style -> $REPO"
