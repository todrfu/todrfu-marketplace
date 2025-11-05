#!/usr/bin/env bash
# /**
#  * Claude API Key 重启脚本 - 用于在切换 API Key 后重启 Claude Code
#  * 使用指定名称的 Key（或默认 Key）从 ~/.claude/claude-api-project-keys.json 读取
#  * 并导出 ANTHROPIC_AUTH_TOKEN 和 ANTHROPIC_BASE_URL，然后启动 Claude
#  *
#  * @author AI Assistant
#  * @date 2025-11-04 20:00:00
#  */

set -euo pipefail

KEYS_FILE="$HOME/.claude/claude-api-project-keys.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_HELPER="$SCRIPT_DIR/json-helper.py"

# 掩码显示 Key（前 8 位 + … + 后 4 位）
mask_key() {
  local k="$1"
  local len=${#k}
  if (( len <= 12 )); then
    printf '%s' "$k"
  else
    printf '%s…%s' "${k:0:8}" "${k: -4}"
  fi
}

die() { echo "Error: $*" >&2; exit 1; }

# 检查依赖
if ! command -v python3 >/dev/null 2>&1; then
  die "python3 未安装，请先安装 Python 3 (通常系统已预装)"
fi

if [ ! -f "$JSON_HELPER" ]; then
  die "未找到 json-helper.py\n期望位置: $JSON_HELPER"
fi

if ! command -v claude >/dev/null 2>&1; then
  die "未找到 claude CLI，请确认已安装并在 PATH 中"
fi

# 参数解析
KEY_NAME="${1:-}"
SESSION_ID="${2:-}"

# 如果存储文件不存在，提示用户
if [ ! -f "$KEYS_FILE" ]; then
  echo "错误: 未找到 API Key 存储文件: $KEYS_FILE"
  echo ""
  echo "请先使用以下命令添加 API Key："
  echo "  $(dirname "$0")/claude-key-manager.sh add"
  echo ""
  exit 1
fi

# 如果未指定 Key 名称，使用默认 Key
if [ -z "$KEY_NAME" ]; then
  KEY_NAME=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")
  if [ -z "$KEY_NAME" ]; then
    echo "错误: 未提供 key-name 且未设置默认 Key"
    echo ""
    echo "请使用以下命令之一："
    echo "  1. 指定 Key 名称: $0 <key-name>"
    echo "  2. 设置默认 Key: $(dirname "$0")/claude-key-manager.sh set-default <key-name>"
    echo "  3. 查看所有 Key: $(dirname "$0")/claude-key-manager.sh list"
    echo ""
    exit 1
  fi
  echo "使用默认 Key: $KEY_NAME"
fi

# 获取 Key 信息
key_info=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$KEY_NAME" 2>/dev/null || echo "")
if [ -z "$key_info" ] || [ "$key_info" == "null" ]; then
  echo "错误: Key 不存在：$KEY_NAME"
  echo ""
  echo "请使用以下命令查看所有可用的 Key："
  echo "  $(dirname "$0")/claude-key-manager.sh list"
  echo ""
  exit 1
fi

# 提取 Key 信息
API_KEY=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
BASE_URL=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('baseUrl', ''))")
note=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('note', ''))")

# 显示即将使用的 Key 信息
masked=$(mask_key "$API_KEY")
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "正在使用 API Key: $KEY_NAME"
echo "  Key: $masked"
if [ -n "$BASE_URL" ]; then
  echo "  Base URL: $BASE_URL"
fi
if [ -n "$note" ]; then
  echo "  描述: $note"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 导出环境变量
export ANTHROPIC_AUTH_TOKEN="$API_KEY"
if [ -n "$BASE_URL" ]; then
  export ANTHROPIC_BASE_URL="$BASE_URL"
fi

# 会话恢复策略
# if [ -n "$SESSION_ID" ]; then
#   echo "正在恢复会话: $SESSION_ID"
#   exec claude --resume "$SESSION_ID"
# fi

# # 检查是否支持 --continue
# if claude --help 2>/dev/null | grep -q -- '--continue'; then
#   echo "正在启动 Claude Code (继续模式)..."
#   exec claude --continue
# else
#   echo "正在启动 Claude Code..."
#   exec claude
# fi
