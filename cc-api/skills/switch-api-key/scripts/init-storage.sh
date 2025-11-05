#!/usr/bin/env bash
# /**
#  * 初始化并创建 ~/.claude/claude-api-project-keys.json（权限 0600），若已存在则跳过（除非 --force）。
#  *
#  * @author AI Assistant
#  * @date 2025-11-01 20:45:30
#  */

set -euo pipefail

KEYS_FILE="$HOME/.claude/claude-api-project-keys.json"

usage() {
  echo "Usage: $(basename "$0") [--force] [--with-sample]" >&2
}

FORCE=0
WITH_SAMPLE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --with-sample) WITH_SAMPLE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [ -f "$KEYS_FILE" ] && [ $FORCE -ne 1 ]; then
  echo "Exists: $KEYS_FILE (use --force to overwrite)"
  exit 0
fi

tmpfile=$(mktemp)

if [ $WITH_SAMPLE -eq 1 ]; then
  cat >"$tmpfile" <<'JSON'
{
  "version": 1,
  "keys": [
    {
      "name": "project-x",
      "key": "anthropic-api-key-xxxxxxxxxxxxxxxx",
      "createdAt": "2025-05-28T10:00:00Z",
      "note": "示例"
    }
  ],
  "default": "project-x"
}
JSON
else
  cat >"$tmpfile" <<'JSON'
{
  "version": 1,
  "keys": [],
  "default": ""
}
JSON
fi

mv "$tmpfile" "$KEYS_FILE"
chmod 600 "$KEYS_FILE"
echo "Initialized: $KEYS_FILE (mode 600)"


