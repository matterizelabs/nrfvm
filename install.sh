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
SKIP_CHECKSUM="${NRFVM_SKIP_CHECKSUM:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"

SHASUM_FILE="$INSTALL_DIR/.shasum"

declare -A ASSET_SHA256
ASSET_SHA256[nrfvm]=""
ASSET_SHA256[completions/nrfvm.bash]=""
ASSET_SHA256[completions/_nrfvm]=""

log() {
  printf "%s\n" "$1"
}

err() {
  printf "install.sh: %s\n" "$1" >&2
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

sha256_file() {
  local file="$1"
  if have_cmd sha256sum; then
    sha256sum "$file" | cut -d' ' -f1
  elif have_cmd shasum; then
    shasum -a 256 "$file" | cut -d' ' -f1
  else
    printf ""
  fi
}

verify_checksum() {
  local file="$1"
  local expected="$2"

  if [ "$SKIP_CHECKSUM" = "1" ]; then
    return 0
  fi

  if [ -z "$expected" ]; then
    err "no checksum available for $(basename "$file"); set NRFVM_SKIP_CHECKSUM=1 to bypass"
    return 1
  fi

  local actual
  actual="$(sha256_file "$file")"
  if [ -z "$actual" ]; then
    err "no checksum tool available (need sha256sum or shasum); set NRFVM_SKIP_CHECKSUM=1 to bypass"
    return 1
  fi

  if [ "$actual" != "$expected" ]; then
    err "checksum mismatch for $(basename "$file")"
    err "  expected: $expected"
    err "  actual:   $actual"
    err "refuse to install; set NRFVM_SKIP_CHECKSUM=1 only if you understand the risk"
    return 1
  fi
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

fetch_checksums() {
  if [ "$SKIP_CHECKSUM" = "1" ]; then
    return 0
  fi

  local checksum_url="$RAW_BASE/SHA256SUMS"
  local tmp_checksums
  tmp_checksums="$(mktemp)"

  if ! download "$checksum_url" "$tmp_checksums" 2>/dev/null; then
    err "could not fetch checksums from $checksum_url"
    err "set NRFVM_SKIP_CHECKSUM=1 to install without verification (not recommended)"
    rm -f "$tmp_checksums"
    return 1
  fi

  local rel=""
  for rel in nrfvm completions/nrfvm.bash completions/_nrfvm; do
    local expected
    expected="$(grep -F "$rel" "$tmp_checksums" | head -n 1 | cut -d' ' -f1)"
    ASSET_SHA256[$rel]="$expected"
  done

  rm -f "$tmp_checksums"
}

install_asset() {
  local rel="$1"
  local dest="$2"
  local local_src="$SCRIPT_DIR/$rel"

  if [ "$INSTALL_MODE" = "local" ] || [ "$INSTALL_MODE" = "auto" ]; then
    if [ -f "$local_src" ]; then
      cp "$local_src" "$dest"
      if [ "$SKIP_CHECKSUM" != "1" ]; then
        verify_checksum "$dest" "${ASSET_SHA256[$rel]}" || {
          err "local file checksum mismatch for $rel"
          rm -f "$dest"
          return 1
        }
      fi
      return 0
    fi
  fi

  if [ "$INSTALL_MODE" = "local" ]; then
    err "local mode requested but file not found: $local_src"
    return 1
  fi

  local url="$RAW_BASE/$rel"
  download "$url" "$dest"
  verify_checksum "$dest" "${ASSET_SHA256[$rel]}" || {
    rm -f "$dest"
    return 1
  }
}

prompt_yes_no() {
  local prompt="$1"
  local answer=""
  printf "%s [y/N]: " "$prompt" >&2
  IFS= read -r answer || true
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
fetch_checksums

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

RC_FILES_MODIFIED=0

for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc_file" ]; then
    case "$rc_file" in
      *.bashrc)
        if ! grep -Fq "$BASH_LINE" "$rc_file" || ! grep -Fq "$BASH_COMPLETION_LINE" "$rc_file"; then
          if prompt_yes_no "add nrfvm source lines to $rc_file?"; then
            append_if_missing "$rc_file" "$BASH_LINE"
            append_if_missing "$rc_file" "$BASH_COMPLETION_LINE"
            RC_FILES_MODIFIED=1
          fi
        fi
        ;;
      *.zshrc)
        if ! grep -Fq "$ZSH_LINE" "$rc_file" || ! grep -Fq "$ZSH_COMPLETION_LINE" "$rc_file"; then
          if prompt_yes_no "add nrfvm source lines to $rc_file?"; then
            append_if_missing "$rc_file" "$ZSH_LINE"
            append_if_missing "$rc_file" "$ZSH_COMPLETION_LINE"
            RC_FILES_MODIFIED=1
          fi
        fi
        ;;
    esac
  fi
done

log "Installed nrfvm to $TARGET_SCRIPT"
log "Copied executable to $TARGET_BIN"
if [ "$RC_FILES_MODIFIED" = "1" ]; then
  log "Updated shell rc files"
else
  log "Add to your shell: source \"$TARGET_SCRIPT\""
fi
log "Open a new shell or run: source \"$TARGET_SCRIPT\""