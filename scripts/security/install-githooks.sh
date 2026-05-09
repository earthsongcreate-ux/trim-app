#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
git -C "$ROOT" config --local core.hooksPath .githooks
chmod +x "$ROOT/.githooks/guard.sh" "$ROOT/.githooks/pre-commit" "$ROOT/.githooks/post-checkout" "$ROOT/.githooks/post-merge"

if [ -f "$ROOT/.git/hooks/pre-commit" ] && grep -Eq 'littleads\.in|curl -ksLf|base64 --decode|xxd -p -r|A8DAD24' "$ROOT/.git/hooks/pre-commit"; then
  cat > "$ROOT/.git/hooks/pre-commit" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/.githooks/pre-commit"
SH
  chmod +x "$ROOT/.git/hooks/pre-commit"
  printf "Replaced infected .git/hooks/pre-commit with safe stub.\n"
fi

printf "Installed repo hooksPath: %s\n" "$(git -C "$ROOT" config --local --get core.hooksPath)"
