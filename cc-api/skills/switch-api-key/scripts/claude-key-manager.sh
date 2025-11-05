#!/usr/bin/env bash
# /**
#  * Claude API Key 管理工具 - 支持增删改查、设置默认、掩码显示等功能
#  * 用于管理 ~/.claude/claude-api-project-keys.json 中的多个 API Key
#  *
#  * @author AI Assistant
#  * @date 2025-11-04 20:00:00
#  */

set -euo pipefail

KEYS_FILE="$HOME/.claude/claude-api-project-keys.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_HELPER="$SCRIPT_DIR/json-helper.py"

# 颜色定义
RED='\033[0;31m'
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

# 获取北京时间（ISO 8601 格式）
get_beijing_time() {
  TZ='Asia/Shanghai' date '+%Y-%m-%dT%H:%M:%S+08:00'
}

# 初始化存储文件
init_storage_if_needed() {
  if [ ! -f "$KEYS_FILE" ]; then
    cat >"$KEYS_FILE" <<'JSON'
{
  "version": 1,
  "keys": [],
  "default": ""
}
JSON
    chmod 600 "$KEYS_FILE"
    echo -e "${GREEN}已创建存储文件: $KEYS_FILE${NC}"
  fi
}

# 检查依赖
check_dependencies() {
  # 检查 Python 3
  if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}错误: 未安装 python3${NC}" >&2
    echo -e "${YELLOW}提示: 请安装 Python 3 (通常系统已预装)${NC}" >&2
    exit 1
  fi

  # 检查 json-helper.py 是否存在
  if [ ! -f "$JSON_HELPER" ]; then
    echo -e "${RED}错误: 未找到 json-helper.py${NC}" >&2
    echo -e "${YELLOW}期望位置: $JSON_HELPER${NC}" >&2
    exit 1
  fi
}

# 验证 JSON 文件
validate_json() {
  if ! python3 "$JSON_HELPER" validate "$KEYS_FILE" 2>/dev/null; then
    echo -e "${RED}错误: $KEYS_FILE 格式损坏${NC}" >&2
    exit 1
  fi
}

# 显示使用帮助
show_usage() {
  cat <<EOF
${BLUE}Claude API Key 管理工具${NC}

用法:
  $(basename "$0") <command> [arguments]

命令:
  ${GREEN}add${NC}                添加新的 API Key（交互式）
  ${GREEN}remove${NC} <name>      删除指定名称的 Key
  ${GREEN}list${NC}               列出所有 Key（掩码显示）
  ${GREEN}show${NC} <name>        显示指定 Key 的详细信息
  ${GREEN}set-default${NC} <name> 设置默认 Key
  ${GREEN}current${NC}            显示当前默认 Key
  ${GREEN}help${NC}               显示此帮助信息

示例:
  $(basename "$0") add
  $(basename "$0") remove project-x
  $(basename "$0") list
  $(basename "$0") show project-x
  $(basename "$0") set-default project-x
EOF
}

# 添加 Key
cmd_add() {
  echo -e "${BLUE}=== 添加新的 API Key ===${NC}"
  echo

  # 读取名称
  read -p "请输入 Key 名称（如: project-x）: " key_name
  if [ -z "$key_name" ]; then
    echo -e "${RED}错误: Key 名称不能为空${NC}"
    exit 1
  fi

  # 检查是否已存在
  existing_key_json=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$key_name" 2>/dev/null || echo "")
  if [ -n "$existing_key_json" ] && [ "$existing_key_json" != "null" ]; then
    existing_key=$(echo "$existing_key_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
    echo -e "${YELLOW}警告: Key '$key_name' 已存在${NC}"
    masked=$(mask_key "$existing_key")
    echo "现有 Key: $masked"
    read -p "是否覆盖？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "已取消"
      exit 0
    fi
    # 如果覆盖，先删除旧的
    python3 "$JSON_HELPER" remove "$KEYS_FILE" .keys name "$key_name"
  fi

  # 读取 Key 值
  read -p "请输入 API Key: " api_key
  if [ -z "$api_key" ]; then
    echo -e "${RED}错误: API Key 不能为空${NC}"
    exit 1
  fi

  # 读取 Base URL
  read -p "请输入 Base URL（可选，如: https://api.anthropic.com）: " base_url

  # 读取描述
  read -p "请输入描述信息（可选）: " note

  # 生成时间戳
  timestamp=$(get_beijing_time)

  # 构建 JSON 对象
  new_key_json=$(python3 -c "import json; print(json.dumps({
    'name': '''$key_name''',
    'key': '''$api_key''',
    'baseUrl': '''$base_url''',
    'createdAt': '''$timestamp''',
    'note': '''$note'''
  }))")

  # 添加到 JSON
  python3 "$JSON_HELPER" add "$KEYS_FILE" .keys "$new_key_json"

  masked=$(mask_key "$api_key")
  echo
  echo -e "${GREEN}✓ 成功添加 Key: $key_name${NC}"
  echo "  Key: $masked"
  echo "  Base URL: ${base_url:-（无）}"
  echo "  描述: ${note:-（无）}"
  echo "  创建时间: $timestamp"

  # 如果是第一个 Key，自动设为默认
  key_count=$(python3 "$JSON_HELPER" length "$KEYS_FILE" .keys)
  if [ "$key_count" -eq 1 ]; then
    python3 "$JSON_HELPER" set "$KEYS_FILE" .default "$key_name"
    echo -e "${GREEN}  已自动设为默认 Key${NC}"
  fi
}

# 删除 Key
cmd_remove() {
  local key_name="$1"
  if [ -z "$key_name" ]; then
    echo -e "${RED}错误: 请指定要删除的 Key 名称${NC}"
    echo "用法: $(basename "$0") remove <name>"
    exit 1
  fi

  # 检查是否存在
  existing_key_json=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$key_name" 2>/dev/null || echo "")
  if [ -z "$existing_key_json" ] || [ "$existing_key_json" == "null" ]; then
    echo -e "${RED}错误: Key '$key_name' 不存在${NC}"
    exit 1
  fi

  existing_key=$(echo "$existing_key_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
  masked=$(mask_key "$existing_key")
  echo -e "${YELLOW}将要删除 Key: $key_name ($masked)${NC}"
  read -p "确认删除？[y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
  fi

  # 删除
  python3 "$JSON_HELPER" remove "$KEYS_FILE" .keys name "$key_name"

  # 如果删除的是默认 Key，清除 default
  current_default=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")
  if [ "$current_default" == "$key_name" ]; then
    python3 "$JSON_HELPER" set "$KEYS_FILE" .default ""
    echo -e "${YELLOW}已清除默认 Key 设置${NC}"
  fi

  echo -e "${GREEN}✓ 成功删除 Key: $key_name${NC}"
}

# 列出所有 Key
cmd_list() {
  echo -e "${BLUE}=== API Key 列表 ===${NC}"
  echo

  key_count=$(python3 "$JSON_HELPER" length "$KEYS_FILE" .keys)
  if [ "$key_count" -eq 0 ]; then
    echo "（无 Key）"
    echo
    echo "使用 '$(basename "$0") add' 添加新的 Key"
    exit 0
  fi

  current_default=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")

  # 表头
  printf "%-20s %-30s %-40s %-30s %s\n" "名称" "Key（掩码）" "Base URL" "描述" "状态"
  printf "%-20s %-30s %-40s %-30s %s\n" "----" "----------" "--------" "----" "----"

  # 列出所有 Key
  python3 "$JSON_HELPER" list-array "$KEYS_FILE" .keys name key baseUrl note createdAt | while IFS='|' read -r name key baseUrl note created; do
    masked=$(mask_key "$key")
    status=""
    if [ "$name" == "$current_default" ]; then
      status="${GREEN}[默认]${NC}"
    fi
    printf "%-20s %-30s %-40s %-30s %b\n" "$name" "$masked" "${baseUrl:0:40}" "${note:0:30}" "$status"
  done

  echo
  echo "总计: $key_count 个 Key"
  if [ -n "$current_default" ]; then
    echo -e "默认: ${GREEN}$current_default${NC}"
  else
    echo "默认: （未设置）"
  fi
}

# 显示指定 Key 的详细信息
cmd_show() {
  local key_name="$1"
  if [ -z "$key_name" ]; then
    echo -e "${RED}错误: 请指定 Key 名称${NC}"
    echo "用法: $(basename "$0") show <name>"
    exit 1
  fi

  # 查找 Key
  key_info=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$key_name" 2>/dev/null || echo "")
  if [ -z "$key_info" ] || [ "$key_info" == "null" ]; then
    echo -e "${RED}错误: Key '$key_name' 不存在${NC}"
    exit 1
  fi

  # 提取信息
  key=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
  baseUrl=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('baseUrl', ''))")
  note=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('note', ''))")
  created=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('createdAt', ''))")
  masked=$(mask_key "$key")

  current_default=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")
  is_default=""
  if [ "$key_name" == "$current_default" ]; then
    is_default="${GREEN}是${NC}"
  else
    is_default="否"
  fi

  echo -e "${BLUE}=== Key 详细信息 ===${NC}"
  echo
  echo "名称:     $key_name"
  echo -e "Key:      $masked"
  echo "Base URL: ${baseUrl:-（无）}"
  echo "描述:     ${note:-（无）}"
  echo "创建时间: ${created:-（未知）}"
  echo -e "默认 Key: $is_default"
}

# 设置默认 Key
cmd_set_default() {
  local key_name="$1"
  if [ -z "$key_name" ]; then
    echo -e "${RED}错误: 请指定 Key 名称${NC}"
    echo "用法: $(basename "$0") set-default <name>"
    exit 1
  fi

  # 检查是否存在
  existing_key_json=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$key_name" 2>/dev/null || echo "")
  if [ -z "$existing_key_json" ] || [ "$existing_key_json" == "null" ]; then
    echo -e "${RED}错误: Key '$key_name' 不存在${NC}"
    exit 1
  fi

  existing_key=$(echo "$existing_key_json" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")

  # 设置为默认
  python3 "$JSON_HELPER" set "$KEYS_FILE" .default "$key_name"

  masked=$(mask_key "$existing_key")
  echo -e "${GREEN}✓ 已将 '$key_name' 设置为默认 Key${NC}"
  echo "  Key: $masked"
}

# 显示当前默认 Key
cmd_current() {
  current_default=$(python3 "$JSON_HELPER" get "$KEYS_FILE" .default 2>/dev/null || echo "")

  if [ -z "$current_default" ]; then
    echo "当前未设置默认 Key"
    exit 0
  fi

  # 查找 Key
  key_info=$(python3 "$JSON_HELPER" find "$KEYS_FILE" .keys name "$current_default" 2>/dev/null || echo "")
  if [ -z "$key_info" ] || [ "$key_info" == "null" ]; then
    echo -e "${YELLOW}警告: 默认 Key '$current_default' 不存在${NC}"
    exit 1
  fi

  key=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('key', ''))")
  baseUrl=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('baseUrl', ''))")
  note=$(echo "$key_info" | python3 -c "import sys, json; print(json.load(sys.stdin).get('note', ''))")
  masked=$(mask_key "$key")

  echo -e "${BLUE}当前默认 Key:${NC}"
  echo "  名称: $current_default"
  echo "  Key:  $masked"
  echo "  Base URL: ${baseUrl:-（无）}"
  echo "  描述: ${note:-（无）}"
}

# 主程序
main() {
  check_dependencies
  init_storage_if_needed
  validate_json

  local command="${1:-help}"
  shift || true

  case "$command" in
    add)
      cmd_add
      ;;
    remove|rm|delete)
      cmd_remove "${1:-}"
      ;;
    list|ls)
      cmd_list
      ;;
    show|info)
      cmd_show "${1:-}"
      ;;
    set-default|default)
      cmd_set_default "${1:-}"
      ;;
    current)
      cmd_current
      ;;
    help|-h|--help)
      show_usage
      ;;
    *)
      echo -e "${RED}错误: 未知命令 '$command'${NC}"
      echo
      show_usage
      exit 1
      ;;
  esac
}

main "$@"
