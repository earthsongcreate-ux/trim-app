#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUSPECT_RE='littleads\.in|curl -ksLf|base64 --decode|xxd -p -r|sh -c "\$\{A8DAD24\}"|A8DAD24'

fail() {
  printf "\nSECURITY WARNING: %s\n" "$1" 1>&2
  exit 1
}

warn() {
  printf "\nSECURITY WARNING: %s\n" "$1" 1>&2
}

scan_file() {
  local file="$1"
  if [ "$file" = "$ROOT/.githooks/guard.sh" ]; then
    return 0
  fi
  if [ -f "$file" ] && grep -Eq "$SUSPECT_RE" "$file"; then
    local hooks_path
    hooks_path="$(git -C "$ROOT" config --local --get core.hooksPath 2>/dev/null || true)"
    if [[ "$file" == "$ROOT/.git/hooks/"* ]] && [ "$hooks_path" = ".githooks" ]; then
      warn "Suspicious pattern detected in unused hook path: $file"
      return 0
    fi
    fail "Suspicious pattern detected in: $file"
  fi
}

scan_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    while IFS= read -r -d '' f; do
      scan_file "$f"
    done < <(find "$dir" -type f -maxdepth 2 -print0 2>/dev/null || true)
  fi
}

scan_dir "$ROOT/.git/hooks"
scan_dir "$ROOT/.githooks"
scan_file "$ROOT/Trim.xcodeproj/project.pbxproj"

if [ "$(git -C "$ROOT" config --local --get core.hooksPath 2>/dev/null || true)" != ".githooks" ]; then
  warn "core.hooksPath is not set. Run: scripts/security/install-githooks.sh"
fi

exit 0
