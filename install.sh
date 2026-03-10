#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${NRFVM_INSTALL_DIR:-$HOME/.local/share/nrfvm}"
BIN_DIR="${NRFVM_BIN_DIR:-$HOME/.local/bin}"
TARGET_SCRIPT="$INSTALL_DIR/nrfvm"
TARGET_BIN="$BIN_DIR/nrfvm"
TARGET_BASH_COMPLETION="$INSTALL_DIR/completions/nrfvm.bash"
TARGET_ZSH_COMPLETION="$INSTALL_DIR/completions/_nrfvm"

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
cp "$SRC_DIR/nrfvm" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
cp "$TARGET_SCRIPT" "$TARGET_BIN"
mkdir -p "$INSTALL_DIR/completions"
cp "$SRC_DIR/completions/nrfvm.bash" "$TARGET_BASH_COMPLETION"
cp "$SRC_DIR/completions/_nrfvm" "$TARGET_ZSH_COMPLETION"

append_if_missing() {
  local file="$1"
  local line="$2"
  [ -f "$file" ] || touch "$file"
  if ! grep -Fq "$line" "$file"; then
    printf "\n%s\n" "$line" >> "$file"
  fi
}

BASH_LINE="[ -s \"$TARGET_SCRIPT\" ] && source \"$TARGET_SCRIPT\""
ZSH_LINE="[ -s \"$TARGET_SCRIPT\" ] && source \"$TARGET_SCRIPT\""
BASH_COMPLETION_LINE="[ -s \"$TARGET_BASH_COMPLETION\" ] && source \"$TARGET_BASH_COMPLETION\""
ZSH_COMPLETION_LINE="fpath=(\"$INSTALL_DIR/completions\" $fpath)"

append_if_missing "$HOME/.bashrc" "$BASH_LINE"
append_if_missing "$HOME/.zshrc" "$ZSH_LINE"
append_if_missing "$HOME/.bashrc" "$BASH_COMPLETION_LINE"
append_if_missing "$HOME/.zshrc" "$ZSH_COMPLETION_LINE"

echo "Installed nrfvm to $TARGET_SCRIPT"
echo "Copied executable to $TARGET_BIN"
echo "Updated ~/.bashrc and ~/.zshrc"
echo "Open a new shell or run: source \"$TARGET_SCRIPT\""
