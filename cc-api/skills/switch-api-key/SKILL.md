---
name: switch-api-key
description: "Claude API Key 管理工具，支持在多个 API Key 之间快速切换、查看、添加、删除和管理。当用户需要：(1) 切换不同项目的 API Key，(2) 管理多个 API Key，(3) 查看当前使用的 Key，(4) 添加或删除 API Key 时使用此技能"
license: MIT
---

# Claude API Key 切换与管理

## 概述

此技能提供了完整的 Claude API Key 管理功能，允许用户在多个 API Key 之间快速切换，并提供增删改查等管理操作。所有 Key 以掩码形式显示（前8位…后4位），确保安全性。

## 核心功能

### 1. 切换 API Key
直接修改 `~/.claude/settings.json` 中的 `env` 配置，用户只需重启 Claude Code 即可生效。

**实现方式**:
- 读取指定的 Key 和 Base URL
- 更新 `~/.claude/settings.json` 中的 `env.ANTHROPIC_AUTH_TOKEN` 和 `env.ANTHROPIC_BASE_URL`
- 自动备份原配置文件
- 保留其他配置项不变

**优点**: 配置持久化，无需运行额外脚本，只需简单重启 `claude` 命令即可。

### 2. 查看管理
- 列出所有已保存的 API Key
- 查看指定 Key 的详细信息
- 显示当前正在使用的默认 Key

### 3. 添加删除
- 交互式添加新的 API Key
- 删除不再需要的 Key
- 设置默认 Key

## 使用场景

### 场景 1: 切换到指定 Key
当用户需要切换到特定项目的 API Key 时：

#### 方式 1：在 Claude Code 中使用 /api use（推荐）
```bash
/api use <key-name>
```

**行为：**
1. 从 `~/.claude/claude-api-project-keys.json` 读取指定名称的 Key 和 Base URL
2. 备份原配置到 `~/.claude/settings.json.backup`
3. 更新 `~/.claude/settings.json` 中的 `env.ANTHROPIC_AUTH_TOKEN` 和 `env.ANTHROPIC_BASE_URL`
4. 保留其他配置（`enabledPlugins`、`statusLine`、`alwaysThinkingEnabled` 等）不变
5. 显示重启提示

**输出示例：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
正在切换到 API Key: cr-wx-main
  Key: sk-S8twX…aX2m
  Base URL: https://api.codemirror.codes/
  描述: code router wechat(main).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

已备份原配置到: ~/.claude/settings.json.backup

✓ 成功更新 Claude settings

⚠️  需要重启 Claude Code 才能生效

请执行以下步骤：
1. 连续按 Ctrl + C 或输入 /exit 退出当前会话
2. 在终端中重新运行 'claude' 命令启动

提示：新会话将自动使用 Key: cr-wx-main (sk-S8twX…aX2m)

当前 Claude settings.json 中的 env 配置：
  {
    "ANTHROPIC_AUTH_TOKEN": "sk-S8twX...",
    "ANTHROPIC_BASE_URL": "https://api.codemirror.codes/"
  }
```

#### 方式 2：命令行使用 claude-api-use.sh
```bash
# 在 scripts 目录下执行
./claude-api-use.sh <key-name>
```

**参数说明：**
- `key-name`: 可选，Key 的名称（如 project-x）。不提供则使用默认 Key

**行为：**
与方式 1 相同，直接修改 `~/.claude/settings.json`。适用于在命令行环境中切换 API Key 的场景。

#### 方式 3：使用 claude-api-restart.sh（适用于命令行启动）
```bash
# 在 scripts 目录下执行
./claude-api-restart.sh <key-name> [session-id]
```

**参数说明：**
- `key-name`: 可选，Key 的名称（如 project-x）。不提供则使用默认 Key
- `session-id`: 可选，指定要恢复的会话 ID

**行为：**
1. 从 `~/.claude/claude-api-project-keys.json` 读取指定名称的 Key 和 Base URL
2. 导出 `ANTHROPIC_AUTH_TOKEN` 和 `ANTHROPIC_BASE_URL` 环境变量
3. 直接启动 Claude Code（使用 `--resume`、`--continue` 或直接启动）

**适用场景：** 当您想要在终端中一次性切换并启动 Claude Code 时使用。

**输出示例：**
```
使用默认 Key: cr-wx-main
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
正在使用 API Key: cr-wx-main
  Key: sk-S8twX…aX2m
  Base URL: https://api.codemirror.codes/
  描述: code router wechat(main).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

正在启动 Claude Code (继续模式)...
```

### 场景 2: 查看所有 Key
列出所有已保存的 API Key（掩码显示）：

```bash
./claude-key-manager.sh list
```

**输出示例：**
```
=== API Key 列表 ===

名称                 Key（掩码）                    描述                           状态
----                 ----------                    ----                           ----
project-x            sk-ant-a...b1c2               生产环境 Key                    [默认]
project-y            sk-ant-d...e3f4               测试环境 Key                    

总计: 2 个 Key
默认: project-x
```

### 场景 3: 查看 Key 详情
显示指定 Key 的完整信息：

```bash
./claude-key-manager.sh show <key-name>
```

**输出示例：**
```
=== Key 详细信息 ===

名称:     project-x
Key:      sk-ant-a...b1c2
Base URL: https://api.anthropic.com
描述:     生产环境 Key
创建时间: 2025-11-01T18:30:00+08:00
默认 Key: 是
```

### 场景 4: 添加新 Key
交互式添加新的 API Key：

```bash
./claude-key-manager.sh add
```

**交互流程：**
1. 输入 Key 名称（如 project-x）
2. 输入 API Key 值
3. 输入 Base URL（可选，如 https://api.anthropic.com）
4. 输入描述信息（可选）
5. 自动记录创建时间（北京时间）
5. 如果是第一个 Key，自动设为默认

**注意事项：**
- 如果名称已存在，会提示是否覆盖
- 第一个添加的 Key 会自动设为默认
- 所有 Key 存储在 `~/.claude/claude-api-project-keys.json`（权限 600）

### 场景 5: 删除 Key
删除指定名称的 Key：

```bash
./claude-key-manager.sh remove <key-name>
```

**行为：**
1. 显示要删除的 Key（掩码）
2. 要求确认
3. 如果删除的是默认 Key，会清除默认设置

### 场景 6: 设置默认 Key
将指定 Key 设置为默认（未指定名称时使用）：

```bash
./claude-key-manager.sh set-default <key-name>
```

### 场景 7: 查看当前默认 Key
显示当前正在使用的默认 Key：

```bash
./claude-key-manager.sh current
```

## 脚本说明

### claude-key-manager.sh
主要的管理工具，提供完整的 CRUD 操作。

**命令列表：**
- `add` - 添加新的 API Key（交互式）
- `remove <name>` - 删除指定名称的 Key
- `list` - 列出所有 Key（掩码显示）
- `show <name>` - 显示指定 Key 的详细信息
- `set-default <name>` - 设置默认 Key
- `current` - 显示当前默认 Key
- `help` - 显示帮助信息

### claude-api-use.sh
用于切换 API Key 并修改 `~/.claude/settings.json`（推荐使用）。

**用法：**
```bash
./claude-api-use.sh [key-name]
```

**参数：**
- `key-name`: 可选，不提供则使用默认 Key

**特性：**
- 直接修改 `~/.claude/settings.json` 中的 `env` 配置
- 自动备份原配置文件到 `~/.claude/settings.json.backup`
- 保留其他配置项（`enabledPlugins`、`statusLine` 等）不变
- 使用 `jq` 安全地更新 JSON
- 配置持久化，重启后自动生效
- 清晰的成功提示和配置展示

**推荐场景：**
- 在 Claude Code 中使用 `/api use` 命令（自动调用）
- 在命令行中切换 API Key 后手动重启 Claude Code

### claude-api-restart.sh
用于切换 API Key 并立即启动 Claude Code（适用于命令行启动场景）。

**用法：**
```bash
./claude-api-restart.sh [key-name] [session-id]
```

**参数：**
- `key-name`: 可选，不提供则使用默认 Key
- `session-id`: 可选，指定要恢复的会话 ID

**会话恢复策略：**
1. 如果提供了 `session-id`，使用 `claude --resume <session-id>`
2. 否则，如果 Claude CLI 支持 `--continue`，使用 `claude --continue`
3. 否则，直接启动 `claude`

**特性：**
- 导出环境变量（`ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_BASE_URL`）
- 使用 `exec` 启动 Claude Code
- 支持会话恢复和继续模式
- 一次性切换并启动

**推荐场景：**
- 在终端中想要一次性切换并启动 Claude Code
- 需要恢复特定会话时

### claude-switch.sh（已废弃）
旧版切换工具，使用 `exec` 替换当前进程。

**不推荐使用的原因：**
- 使用 `exec` 会完全替换当前进程，破坏用户工作流程
- 在 Claude Code 中调用时会出错（无法访问 stdin）
- 无法可靠地恢复会话状态
- 环境变量作用域限制

**替代方案：**
- 使用 `claude-api-use.sh` 修改配置文件（推荐）
- 使用 `claude-api-restart.sh` 一次性切换并启动

### init-storage.sh
初始化存储文件（通常不需要手动调用）。

**用法：**
```bash
./init-storage.sh [--force] [--with-sample]
```

**选项：**
- `--force`: 强制覆盖已存在的文件
- `--with-sample`: 创建带示例数据的文件

## 数据存储

### 存储位置
`~/.claude/claude-api-project-keys.json`

### 文件权限
600（仅所有者可读写）

### 数据结构
```json
{
  "version": 1,
  "keys": [
    {
      "name": "project-x",
      "key": "sk-ant-api03-...",
      "baseUrl": "https://api.anthropic.com",
      "createdAt": "2025-11-01T18:30:00+08:00",
      "note": "生产环境 Key"
    }
  ],
  "default": "project-x"
}
```

**字段说明：**
- `version`: 数据格式版本号
- `keys`: Key 数组
  - `name`: Key 的名称（唯一标识）
  - `key`: 实际的 API Key 值
  - `baseUrl`: API 基础 URL（可选，用于不同大模型商的接口地址）
  - `createdAt`: 创建时间（ISO 8601 格式，北京时间）
  - `note`: 可选的描述信息
- `default`: 默认 Key 的名称

## 安全特性

### 1. 掩码显示
所有命令输出仅显示 Key 指纹（前8位…后4位），例如：
- 完整 Key: `sk-ant-api03-abcdefghijklmnopqrstuvwxyz1234567890`
- 掩码显示: `sk-ant-a…7890`

### 2. 文件权限
存储文件自动设置为 600 权限，仅所有者可读写。

### 3. 环境变量优先级
`ANTHROPIC_AUTH_TOKEN` 和 `ANTHROPIC_BASE_URL` 环境变量优先于订阅登录。

### 4. 交互确认
删除和覆盖操作需要用户确认。

## 系统要求

### 依赖工具
- **jq**: JSON 处理工具
  ```bash
  # macOS
  brew install jq
  
  # Ubuntu/Debian
  sudo apt-get install jq
  ```

- **Claude CLI**: Claude 命令行工具
  - 需安装并在 PATH 中
  - 用于重启会话

### 支持平台
- macOS
- Linux
- Windows（需要 Git Bash 或 WSL）

## 工作流程示例

### 首次使用
```bash
# 1. 添加第一个 Key
./claude-key-manager.sh add
# 输入: project-x, sk-ant-api03-..., https://api.anthropic.com, 生产环境

# 2. 添加第二个 Key
./claude-key-manager.sh add
# 输入: project-y, sk-ant-api03-..., https://api.anthropic.com, 测试环境

# 3. 查看所有 Key
./claude-key-manager.sh list

# 4. 切换并重启（方式 1：修改配置）
./claude-api-use.sh project-y
# 然后手动重启: claude

# 或（方式 2：一次性切换并启动）
./claude-api-restart.sh project-y
```

### 日常使用（在 Claude Code 中）
```bash
# 查看当前使用的 Key
/api current

# 切换到另一个项目
/api use project-x
# 按照提示退出并重启 claude

# 查看某个 Key 的详情
/api show project-x

# 列出所有 Key
/api list
```

### 日常使用（命令行）
```bash
# 方式 1：修改配置后手动重启
./claude-api-use.sh project-x
# 退出当前 Claude Code，然后运行: claude

# 方式 2：一次性切换并启动
./claude-api-restart.sh project-x

# 查看当前使用的 Key
./claude-key-manager.sh current

# 查看某个 Key 的详情
./claude-key-manager.sh show project-x
```

### 管理维护
```bash
# 设置默认 Key
./claude-key-manager.sh set-default project-x

# 删除不再使用的 Key
./claude-key-manager.sh remove old-project

# 查看所有 Key
./claude-key-manager.sh list
```

## 故障排除

### 问题 1: jq 未安装
**错误信息：** `错误: 未安装 jq，请先安装 jq`

**解决方法：**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### 问题 2: Claude CLI 未找到
**错误信息：** `未找到 claude CLI，请确认已安装并在 PATH 中`

**解决方法：**
1. 确认 Claude CLI 已安装
2. 确认 `claude` 命令在 PATH 中
3. 尝试运行 `which claude` 检查路径

### 问题 3: Key 不存在
**错误信息：** `Key 不存在：<key-name>`

**解决方法：**
1. 运行 `./claude-key-manager.sh list` 查看所有可用的 Key
2. 确认 Key 名称拼写正确
3. 如果需要，使用 `./claude-key-manager.sh add` 添加新 Key

### 问题 4: 存储文件损坏
**错误信息：** `错误: ~/.claude/claude-api-project-keys.json 格式损坏`

**解决方法：**
1. 备份当前文件：`cp ~/.claude/claude-api-project-keys.json ~/.claude/claude-api-project-keys.json.bak`
2. 重新初始化：`./init-storage.sh --force`
3. 重新添加 Key

### 问题 5: 权限问题
**错误信息：** `Permission denied`

**解决方法：**
```bash
# 给脚本添加执行权限
chmod +x scripts/*.sh

# 检查存储文件权限
ls -l ~/.claude/claude-api-project-keys.json
# 应该显示: -rw------- (600)
```

## 最佳实践

### 1. Key 命名规范
- 使用有意义的名称，如 `project-x`、`prod-env`、`test-env`
- 避免使用特殊字符
- 使用小写字母和连字符

### 2. 描述信息
- 添加清晰的描述，说明 Key 的用途
- 包含环境信息（生产/测试/开发）
- 记录项目名称或团队信息

### 3. 定期维护
- 定期检查并删除不再使用的 Key
- 更新过期的 Key
- 备份存储文件

### 4. 安全建议
- 不要在公共场所显示完整 Key
- 定期轮换 API Key
- 不要将存储文件提交到版本控制系统
- 使用不同的 Key 区分不同环境

## 与 Claude Code 集成

此技能可以通过 `/api` 命令在 Claude Code 中直接调用。详见 `commands/api.md` 文档。

## 技术细节

### 时间格式
所有时间戳使用 ISO 8601 格式，时区为北京时间（+08:00）：
```
2025-11-01T18:30:00+08:00
```

### JSON 验证
每次操作前会验证 JSON 文件格式，确保数据完整性。

### 原子操作
所有写操作使用临时文件 + 移动的方式，确保原子性。

### 错误处理
- 使用 `set -euo pipefail` 确保脚本在错误时立即退出
- 所有错误信息输出到 stderr
- 提供清晰的错误提示和解决建议

## 许可证

MIT License

## 更新日志

### v1.0.0 (2025-11-01)
- 初始版本
- 支持基本的 CRUD 操作
- 支持掩码显示
- 支持默认 Key 设置
- 支持会话恢复

