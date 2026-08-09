#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# On demande à pandoc lui-même son data dir (plus fiable qu'un chemin figé)
DATA_DIR="$(pandoc --version 2>/dev/null \
  | grep -i 'data directory' | head -n1 \
  | sed -E 's/^[^:]+:[[:space:]]*//; s/ or .*$//')"

if [ -z "$DATA_DIR" ]; then
  DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pandoc"
  echo "⚠ pandoc introuvable ou sortie inattendue, repli sur : $DATA_DIR"
fi

echo "Dépôt    : $REPO_DIR"
echo "Data dir : $DATA_DIR"
mkdir -p "$DATA_DIR"

for sub in reference-docs filters defaults; do
  target="$DATA_DIR/$sub"
  source="$REPO_DIR/$sub"

  if [ -L "$target" ]; then
    rm -f "$target"
  elif [ -e "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    echo "  ⚠ $target existe déjà (pas un lien) → sauvegardé en $backup"
    mv "$target" "$backup"
  fi

  ln -sfn "$source" "$target"
  echo "  ✓ $sub -> $source"
done

echo
echo "Test : pandoc -d bts-sio -o test.docx source.md"
