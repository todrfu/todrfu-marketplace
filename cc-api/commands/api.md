---
argument-hint: [action] [args]
description: 用于在多个 API Key 之间快速切换，支持查看、添加、管理 Key。
skill: switch-api-key
---

执行操作$1，操作参数$2。

可执行的动作:
- use: 切换到指定的 API Key（直接修改 ~/.claude/settings.json，重启后生效）
- list: 列出所有 API Key
- show: 显示 API Key 详情
- add: 添加新的 API Key
- remove: 删除 API Key
- set-default: 设置默认 API Key
- current: 显示当前 API Key

> **注意**: 此命令调用 `switch-api-key` skill 来执行实际操作。

## 用法

### 切换 API Key
```
/api use <key-name>
```
将指定的 Key 写入 `~/.claude/settings.json` 的 `env` 配置中，用户只需重启 Claude Code 即可生效。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-api-use.sh <key-name>` 命令：
1. 读取指定的 Key 和 Base URL
2. 更新 `~/.claude/settings.json` 中的 `env.ANTHROPIC_AUTH_TOKEN` 和 `env.ANTHROPIC_BASE_URL`
3. 保留其他配置（如 `enabledPlugins`、`statusLine` 等）不变
4. 自动备份原配置文件到 `~/.claude/settings.json.backup`

**示例**:
```
/api use cr-wx-main
```

**输出示例**:
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

**注意**:
- 配置会持久化保存，下次启动 Claude Code 会自动使用
- 原配置文件会自动备份到 `~/.claude/settings.json.backup`
- 其他配置（如 `enabledPlugins`、`statusLine` 等）保持不变
- 只需要简单重启 `claude` 命令即可，无需运行额外脚本

### 查看所有 API
```
/api list
```
列出所有已保存的 API Key（掩码显示）。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh list` 命令。

**输出示例**:
```
=== API Key 列表 ===

名称                 Key（掩码）                    描述                           状态
----                 ----------                    ----                           ----
project-x            sk-ant-a...b1c2               生产环境 Key                    [默认]
project-y            sk-ant-d...e3f4               测试环境 Key                    

总计: 2 个 Key
默认: project-x
```

### 查看 Key 详情
```
/api show <key-name>
```
显示指定 Key 的详细信息（名称、掩码、描述、创建时间等）。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh show <key-name>` 命令。

**示例**:
```
/api show project-x
```

### 查看当前 Key
```
/api current
```
显示当前正在使用的默认 Key。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh current` 命令。

### 添加新 Key
```
/api add
```
交互式添加新的 API Key。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh add` 命令。

**交互流程**:
1. 输入 Key 名称（如: project-x）
2. 输入 API Key 值
3. 输入描述信息（可选）
4. 自动记录创建时间（北京时间）

**注意**: 
- 如果名称已存在，会提示是否覆盖
- 第一个添加的 Key 会自动设为默认

### 删除 Key
```
/api remove <key-name>
```
删除指定名称的 Key。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh remove <key-name>` 命令。

**示例**:
```
/api remove old-project
```

**注意**: 
- 删除前会要求确认
- 如果删除的是默认 Key，会清除默认设置

### 设置默认 Key
```
/api set-default <key-name>
```
将指定 Key 设置为默认（未指定名称时使用）。

**实现方式**: 调用 `switch-api-key` skill 中的 `claude-key-manager.sh set-default <key-name>` 命令。

**示例**:
```
/api set-default project-x
```

## 说明

- **安全显示**：所有命令仅展示 Key 指纹（前8位…后4位），不显示完整 Key
- **持久化配置**：切换后直接修改 `~/.claude/settings.json`，重启后自动生效
- **配置保护**：自动备份原配置，其他设置保持不变
- **优先级**：`~/.claude/settings.json` 中的 env 配置优先于订阅登录
- **存储位置**：
  - API Key 列表：`~/.claude/claude-api-project-keys.json`（权限 600）
  - Claude 配置：`~/.claude/settings.json`

## Key 信息字段

每个 Key 包含以下信息：
- **名称**：便于识别的名称（如 project-x）
- **Key 值**：实际的 API Key
- **描述**：可选的备注信息
- **创建时间**：北京时间，精确到秒

## 快速开始

1. 添加第一个 Key：
   ```bash
   cd cc-api/skills/switch-api-key/scripts
   ./claude-key-manager.sh add
   ```

2. 在 Claude Code 中切换：
   ```
   /api use project-x
   ```

3. 退出并重启：
   ```bash
   # 按 Ctrl+C 或输入 /exit 退出
   # 然后直接重新启动
   claude
   ```

4. 查看所有 Key：
   ```
   /api list
   ```

## Skill 集成

此命令通过调用 `switch-api-key` skill 来执行实际操作。Skill 位于：
```
cc-api/skills/switch-api-key/
```

### Skill 结构
```
switch-api-key/
├── SKILL.md                     # Skill 文档
└── scripts/
    ├── claude-key-manager.sh    # 主要管理工具（CRUD 操作）
    ├── claude-api-use.sh        # 切换工具（修改 settings.json）
    ├── claude-api-restart.sh    # 启动工具（可选，用于命令行）
    ├── claude-switch.sh         # 旧版切换工具（已废弃）
    └── init-storage.sh          # 初始化工具
```

### 命令映射

| /api 命令 | Skill 脚本调用 | 说明 |
|-----------|---------------|------|
| `/api use <name>` | `claude-api-use.sh <name>` | 切换 API Key（修改 settings.json，重启生效） |
| `/api list` | `claude-key-manager.sh list` | 列出所有 Key |
| `/api show <name>` | `claude-key-manager.sh show <name>` | 查看 Key 详情 |
| `/api current` | `claude-key-manager.sh current` | 查看当前默认 Key |
| `/api add` | `claude-key-manager.sh add` | 添加新 Key（交互式） |
| `/api remove <name>` | `claude-key-manager.sh remove <name>` | 删除 Key |
| `/api set-default <name>` | `claude-key-manager.sh set-default <name>` | 设置默认 Key（仅修改 keys 文件） |

### 工作流程

当用户执行 `/api` 命令时：

1. **命令解析**: Claude Code 解析命令和参数
2. **Skill 定位**: 根据 `skill: switch-api-key` 字段定位到对应的 skill
3. **脚本调用**: 调用 skill 中的相应脚本
4. **结果返回**: 将脚本输出返回给用户

### 示例流程

#### 切换 API Key 工作流程
```
用户输入: /api use cr-wx-main
    ↓
Claude Code 解析命令
    ↓
定位到 switch-api-key skill
    ↓
执行: claude-api-use.sh cr-wx-main
    ↓
1. 读取 Key 信息（从 ~/.claude/claude-api-project-keys.json）
2. 备份原配置（~/.claude/settings.json -> settings.json.backup）
3. 更新 env.ANTHROPIC_AUTH_TOKEN 和 env.ANTHROPIC_BASE_URL
4. 保留其他配置不变
    ↓
显示成功提示和重启说明
    ↓
用户退出 (Ctrl+C 或 /exit)
    ↓
用户在终端运行: claude
    ↓
Claude Code 启动，自动使用新的 API Key
```

#### 查看 Key 列表工作流程
```
用户输入: /api list
    ↓
Claude Code 解析命令
    ↓
定位到 switch-api-key skill
    ↓
执行: cd cc-api/skills/switch-api-key/scripts && ./claude-key-manager.sh list
    ↓
返回 Key 列表给用户
```

## 命令行直接使用

除了在 Claude Code 中使用 `/api` 命令，您也可以直接在终端中使用管理工具：

```bash
# 进入 scripts 目录
cd cc-api/skills/switch-api-key/scripts

# 添加 Key（交互式）
./claude-key-manager.sh add

# 列出所有 Key
./claude-key-manager.sh list

# 显示 Key 详情
./claude-key-manager.sh show project-x

# 删除 Key
./claude-key-manager.sh remove project-x

# 设置默认 Key（仅修改 keys 文件）
./claude-key-manager.sh set-default project-x

# 查看当前默认 Key
./claude-key-manager.sh current

# 切换 Key（修改 settings.json，需重启生效）
./claude-api-use.sh project-x

# 可选：使用 claude-api-restart.sh 直接启动（适用于命令行启动场景）
./claude-api-restart.sh project-x
```

## 系统要求

- **依赖**：jq（JSON 处理）
- **平台**：macOS、Linux、Windows
- **Claude CLI**：需安装并在 PATH 中

## 注意事项

⚠️ **名称冲突**：添加同名 Key 时会提示是否覆盖  
⚠️ **删除默认**：删除默认 Key 时会清除默认设置  
⚠️ **首个 Key**：添加的第一个 Key 会自动设为默认

