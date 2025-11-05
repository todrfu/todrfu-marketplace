#!/usr/bin/env bash
# /**
#  * Claude API Key 切换工具 - 修改 ~/.claude/settings.json 中的 env 配置
#  * 用户只需重启 Claude Code 即可生效
#  *
#  * @author AI Assistant
#  * @date 2025-11-04 20:00:00
#  */

set -euo pipefail

KEYS_FILE="$HOME/.claude/claude-api-project-keys.json"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_HELPER="$SCRIPT_DIR/json-helper.py"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

die() { echo -e "${NC}Error: $*" >&2; exit 1; }

# 检查依赖
if ! command -v python3 >/dev/null 2>&1; then
  die "python3 未安装，请先安装 Python 3 (通常系统已预装)"
fi

if [ ! -f "$JSON_HELPER" ]; then
  die "未找到 json-helper.py\n期望位置: $JSON_HELPER"
fi

# 参数解析
KEY_NAME="${1:-}"

# 检查存储文件
if [ ! -f "$KEYS_FILE" ]; then
  die "未找到 API Key 存储文件: $KEYS_FILE\n请先使用 'claude-key-manager.sh add' 添加 API Key"
fi

# 如果未指定 Key 名称，使用默认 Key
if [ -z "$KEY_NAME" ]; then
  KEY_NAME=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")
  if [ -z "$KEY_NAME" ]; then
    die "未提供 key-name 且未设置默认 Key\n请使用 'claude-key-manager.sh set-default <name>' 设置默认 Key"
  fi
fi

# 获取 Key 信息
key_info=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$KEY_NAME" 2>/dev/null || echo "")
if [ -z "$key_info" ] || [ "$key_info" == "null" ]; then
  die "Key 不存在：$KEY_NAME\n请使用 'claude-key-manager.sh list' 查看所有可用的 Key"
fi

# 提取 Key 信息
API_KEY=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
BASE_URL=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('baseUrl', ''))")
note=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('note', ''))")

# 显示即将使用的 Key 信息
masked=$(mask_key "$API_KEY")
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}正在切换到 API Key: $KEY_NAME${NC}"
echo "  Key: $masked"
if [ -n "$BASE_URL" ]; then
  echo "  Base URL: $BASE_URL"
fi
if [ -n "$note" ]; then
  echo "  描述: $note"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 创建或更新 settings.json
if [ ! -f "$CLAUDE_SETTINGS" ]; then
  echo -e "${YELLOW}Claude settings 文件不存在，正在创建...${NC}"
  mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
  echo '{}' > "$CLAUDE_SETTINGS"
fi

# 备份原配置文件
cp "$CLAUDE_SETTINGS" "${CLAUDE_SETTINGS}.backup"
echo -e "已备份原配置到: ${CLAUDE_SETTINGS}.backup"
echo ""

# 读取现有配置
settings_content=$(cat "$CLAUDE_SETTINGS")

# 使用 Python 更新配置文件
# 1. 如果 env 不存在，创建空对象
# 2. 设置 ANTHROPIC_AUTH_TOKEN
# 3. 设置或删除 ANTHROPIC_BASE_URL（如果为空）
python3 << EOF > "${CLAUDE_SETTINGS}.tmp"
import json
import sys

try:
    settings = json.loads('''$settings_content''')
except:
    settings = {}

# 确保 env 存在
if 'env' not in settings:
    settings['env'] = {}

# 设置 TOKEN
settings['env']['ANTHROPIC_AUTH_TOKEN'] = '''$API_KEY'''

# 设置或删除 BASE_URL
if '''$BASE_URL''':
    settings['env']['ANTHROPIC_BASE_URL'] = '''$BASE_URL'''
else:
    if 'ANTHROPIC_BASE_URL' in settings['env']:
        del settings['env']['ANTHROPIC_BASE_URL']

print(json.dumps(settings, indent=2, ensure_ascii=False))
EOF

# 验证生成的 JSON 是否有效
if python3 "$JSON_HELPER" validate "${CLAUDE_SETTINGS}.tmp" 2>/dev/null; then
  mv "${CLAUDE_SETTINGS}.tmp" "$CLAUDE_SETTINGS"
  echo -e "${GREEN}✓ 成功更新 Claude settings${NC}"
  echo ""
else
  rm -f "${CLAUDE_SETTINGS}.tmp"
  die "生成的 settings.json 格式无效，已回滚"
fi

# 同时更新默认 Key（可选，保持一致性）
python3 "$JSON_HELPER" set "$KEYS_FILE" .default "$KEY_NAME"

# 显示完成信息
echo -e "${YELLOW}⚠️  需要重启 Claude Code 才能生效${NC}"
echo ""
echo "请执行以下步骤："
echo "1. 连续按 Ctrl + C 或输入 /exit 退出当前会话"
echo "2. 在终端中重新运行 'claude' 命令启动"
echo ""
echo -e "${BLUE}提示：${NC}新会话将自动使用 Key: $KEY_NAME ($masked)"
echo ""

# 显示更新后的 env 配置
echo -e "${BLUE}当前 Claude settings.json 中的 env 配置：${NC}"
python3 "$JSON_HELPER" format "$CLAUDE_SETTINGS" .env | sed 's/^/  /'
