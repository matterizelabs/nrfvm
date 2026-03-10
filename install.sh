#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${NRFVM_INSTALL_DIR:-$HOME/.local/share/nrfvm}"
BIN_DIR="${NRFVM_BIN_DIR:-$HOME/.local/bin}"
TARGET_SCRIPT="$INSTALL_DIR/nrfvm"
TARGET_BIN="$BIN_DIR/nrfvm"
TARGET_BASH_COMPLETION="$INSTALL_DIR/completions/nrfvm.bash"
TARGET_ZSH_COMPLETION="$INSTALL_DIR/completions/_nrfvm"
REPO="${NRFVM_REPO:-matterizelabs/nrfvm}"
REF="${NRFVM_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"
INSTALL_MODE="${NRFVM_INSTALL_MODE:-auto}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"

log() {
  printf "%s\n" "$1"
}

err() {
  printf "install.sh: %s\n" "$1" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

download() {
  local url="$1"
  local dest="$2"
  if have_cmd curl; then
    curl -fsSL "$url" -o "$dest"
    return 0
  fi
  if have_cmd wget; then
    wget -qO "$dest" "$url"
    return 0
  fi
  err "missing downloader. Install curl or wget."
  return 1
}

install_asset() {
  local rel="$1"
  local dest="$2"
  local local_src="$SCRIPT_DIR/$rel"

  if [ "$INSTALL_MODE" = "local" ] || [ "$INSTALL_MODE" = "auto" ]; then
    if [ -f "$local_src" ]; then
      cp "$local_src" "$dest"
      return 0
    fi
  fi

  if [ "$INSTALL_MODE" = "local" ]; then
    err "local mode requested but file not found: $local_src"
    return 1
  fi

  local url="$RAW_BASE/$rel"
  download "$url" "$dest"
}

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
install_asset "nrfvm" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
cp "$TARGET_SCRIPT" "$TARGET_BIN"
mkdir -p "$INSTALL_DIR/completions"
install_asset "completions/nrfvm.bash" "$TARGET_BASH_COMPLETION"
install_asset "completions/_nrfvm" "$TARGET_ZSH_COMPLETION"

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
ZSH_COMPLETION_LINE="fpath=(\"$INSTALL_DIR/completions\" \$fpath)"

append_if_missing "$HOME/.bashrc" "$BASH_LINE"
append_if_missing "$HOME/.zshrc" "$ZSH_LINE"
append_if_missing "$HOME/.bashrc" "$BASH_COMPLETION_LINE"
append_if_missing "$HOME/.zshrc" "$ZSH_COMPLETION_LINE"

log "Installed nrfvm to $TARGET_SCRIPT"
log "Copied executable to $TARGET_BIN"
log "Updated ~/.bashrc and ~/.zshrc"
log "Open a new shell or run: source \"$TARGET_SCRIPT\""
