/**
 * switch-api-key Skill 概览
 * Claude API Key 管理与切换工具
 *
 * @author AI Assistant
 * @date 2025-11-01 20:45:30
 */

# switch-api-key Skill

> Claude API Key 管理与切换工具 - 支持在多个 API Key 之间快速切换，提供完整的增删改查功能

## 快速开始

### 在 Claude Code 中使用

```
# 查看所有 Key
/api list

# 切换到指定 Key
/api use project-x

# 添加新 Key
/api add

# 查看当前 Key
/api current
```

### 命令行使用

```bash
cd cc-api/skills/switch-api-key/scripts

# 查看所有 Key
./claude-key-manager.sh list

# 添加新 Key
./claude-key-manager.sh add

# 切换 Key（推荐：修改配置文件）
./claude-api-use.sh project-x
# 然后重启: claude

# 或（一次性切换并启动）
./claude-api-restart.sh project-x
```

## 功能特性

- ✅ **多 Key 管理**: 支持添加、删除、查看多个 API Key
- ✅ **快速切换**: 直接修改 settings.json，重启即生效
- ✅ **安全显示**: 所有 Key 以掩码形式显示（前8位…后4位）
- ✅ **默认设置**: 支持设置默认 Key
- ✅ **配置持久化**: 修改保存在 ~/.claude/settings.json
- ✅ **自动备份**: 每次切换自动备份原配置
- ✅ **时间记录**: 自动记录创建时间（北京时间）
- ✅ **描述信息**: 为每个 Key 添加备注说明
- ✅ **权限保护**: 存储文件权限 600，仅所有者可访问

## 目录结构

```
switch-api-key/
├── README.md              # 本文件 - 概览
├── SKILL.md              # 完整的 Skill 文档
└── scripts/              # 可执行脚本
    ├── claude-key-manager.sh    # 主要管理工具（CRUD）
    ├── claude-api-use.sh        # 切换工具（修改 settings.json）⭐
    ├── claude-api-restart.sh    # 启动工具（一次性切换并启动）
    └── init-storage.sh          # 初始化工具
```

## 文档导航

| 文档 | 说明 | 适合人群 |
|------|------|---------|
| [README.md](README.md) | 快速概览和入门 | 所有用户 |
| [SKILL.md](SKILL.md) | 完整的功能文档和 API 参考 | 需要详细了解的用户 |
| [api.md](../../commands/api.md) | /api 命令参考 | Claude Code 用户 |

## 核心命令

### /api 命令（在 Claude Code 中）

| 命令 | 说明 | 示例 |
|------|------|------|
| `/api use <name>` | 切换到指定 Key | `/api use project-x` |
| `/api list` | 列出所有 Key | `/api list` |
| `/api show <name>` | 显示 Key 详情 | `/api show project-x` |
| `/api current` | 显示当前 Key | `/api current` |
| `/api add` | 添加新 Key | `/api add` |
| `/api remove <name>` | 删除 Key | `/api remove old-project` |
| `/api set-default <name>` | 设置默认 Key | `/api set-default project-x` |

### 脚本命令（命令行）

| 脚本 | 说明 | 示例 |
|------|------|------|
| `claude-api-use.sh <name>` | 切换 Key（修改 settings.json）⭐ | `./claude-api-use.sh project-x` |
| `claude-api-restart.sh <name>` | 一次性切换并启动 | `./claude-api-restart.sh project-x` |
| `claude-key-manager.sh list` | 列出所有 Key | `./claude-key-manager.sh list` |
| `claude-key-manager.sh add` | 添加新 Key | `./claude-key-manager.sh add` |
| `claude-key-manager.sh remove <name>` | 删除 Key | `./claude-key-manager.sh remove test` |
| `claude-key-manager.sh show <name>` | 显示详情 | `./claude-key-manager.sh show prod` |
| `claude-key-manager.sh set-default <name>` | 设置默认 | `./claude-key-manager.sh set-default dev` |
| `claude-key-manager.sh current` | 显示当前 | `./claude-key-manager.sh current` |

## 使用场景

### 场景 1: 多项目管理

为不同项目使用不同的 API Key：

```bash
/api add  # 添加 project-a
/api add  # 添加 project-b
/api add  # 添加 project-c

/api use project-a  # 切换到项目 A
```

### 场景 2: 环境分离

区分开发、测试、生产环境：

```bash
/api add  # 添加 dev
/api add  # 添加 test
/api add  # 添加 prod

/api set-default dev  # 开发环境为默认
/api use prod         # 部署时切换到生产
```

### 场景 3: 团队协作

管理个人和团队共享的 Key：

```bash
/api add  # 添加 personal
/api add  # 添加 team-shared

/api use team-shared  # 团队工作时使用
```

## 数据存储

### 存储位置
```
~/.claude/claude-api-project-keys.json
```

### 数据格式
```json
{
  "version": 1,
  "keys": [
    {
      "name": "project-x",
      "key": "sk-ant-api03-...",
      "baseUrl": "https://api.anthropic.com",
      "createdAt": "2025-11-01T20:45:30+08:00",
      "note": "生产环境 Key"
    }
  ],
  "default": "project-x"
}
```

### 安全性
- 文件权限: 600（仅所有者可读写）
- 显示方式: 掩码（sk-ant-a…7890）
- 环境变量: 仅在需要时导出（ANTHROPIC_AUTH_TOKEN, ANTHROPIC_BASE_URL）

## 系统要求

### 必需依赖
- **jq**: JSON 处理工具
  ```bash
  # macOS
  brew install jq
  
  # Ubuntu/Debian
  sudo apt-get install jq
  ```

- **Claude CLI**: Claude 命令行工具
  - 用于切换后重启会话
  - 需在 PATH 中

### 支持平台
- ✅ macOS
- ✅ Linux
- ✅ Windows（Git Bash / WSL）

## 安装和配置

### 1. 克隆或下载项目

```bash
# 项目已包含在 cc-api 插件中
cd /path/to/todrfu-marketplace/cc-api/skills/switch-api-key
```

### 2. 添加执行权限

```bash
cd scripts
chmod +x *.sh
```

### 3. 验证安装

```bash
./claude-key-manager.sh help
```

### 4. 添加第一个 Key

```bash
./claude-key-manager.sh add
```

## 工作原理

### 命令执行流程

```
用户输入: /api list
    ↓
Claude Code 解析命令
    ↓
定位到 switch-api-key skill（通过 skill: 字段）
    ↓
执行: cd scripts && ./claude-key-manager.sh list
    ↓
读取 ~/.claude/claude-api-project-keys.json
    ↓
格式化输出并返回给用户
```

### 切换流程

```
用户输入: /api use project-x
    ↓
执行: ./claude-api-use.sh project-x
    ↓
从 JSON 读取 project-x 的 Key 和 Base URL
    ↓
备份原配置: ~/.claude/settings.json -> settings.json.backup
    ↓
更新 ~/.claude/settings.json 中的 env 配置：
  - env.ANTHROPIC_AUTH_TOKEN
  - env.ANTHROPIC_BASE_URL
    ↓
保留其他配置不变（enabledPlugins、statusLine 等）
    ↓
用户退出并重启 Claude Code
    ↓
新会话自动使用新的 API Key
```

## 常见问题

### Q: 如何查看完整的 API Key？
A: 出于安全考虑，工具不提供查看完整 Key 的功能。如需查看，请直接编辑 `~/.claude/claude-api-project-keys.json` 文件。

### Q: Base URL 有什么用？
A: Base URL 用于指定不同大模型商的 API 接口地址。例如：
- Anthropic 官方: `https://api.anthropic.com`
- 其他代理商: 自定义地址

### Q: 可以在多台机器上同步 Key 吗？
A: 可以。将 `~/.claude/claude-api-project-keys.json` 文件复制到其他机器即可。注意保持文件权限为 600。

### Q: 删除 Key 后可以恢复吗？
A: 无法直接恢复。建议定期备份 `~/.claude/claude-api-project-keys.json` 文件。

### Q: 切换 Key 后需要重启 Claude Code 吗？
A: 是的。使用 `/api use` 命令会修改 `~/.claude/settings.json`，需要退出并重启 `claude` 命令才能生效。配置会持久化保存，下次启动自动使用新的 Key。

### Q: 支持 Windows 吗？
A: 支持。需要使用 Git Bash 或 WSL 环境。

## 故障排除

### 问题: jq 未安装
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

### 问题: 权限被拒绝
```bash
# 添加执行权限
chmod +x scripts/*.sh

# 检查存储文件权限
chmod 600 ~/.claude/claude-api-project-keys.json
```

### 问题: Key 不存在
```bash
# 查看所有可用的 Key
./claude-key-manager.sh list

# 添加新 Key
./claude-key-manager.sh add
```

### 问题: JSON 格式损坏
```bash
# 备份
cp ~/.claude/claude-api-project-keys.json ~/.claude/claude-api-project-keys.json.backup

# 重新初始化
./init-storage.sh --force

# 重新添加 Key
./claude-key-manager.sh add
```

## 最佳实践

1. **命名规范**: 使用清晰、有意义的名称（如 `prod-api`、`dev-env`）
2. **添加描述**: 总是为 Key 添加描述信息，方便日后识别
3. **定期维护**: 删除不再使用的 Key，保持列表整洁
4. **备份数据**: 定期备份 `~/.claude/claude-api-project-keys.json`
5. **环境分离**: 为不同环境使用不同的 Key
6. **安全第一**: 不要在公共场所显示完整 Key
7. **权限检查**: 确保存储文件权限始终为 600

## 贡献和反馈

如有问题、建议或改进意见，欢迎反馈。

## 许可证

MIT License

## 相关链接

- [Claude Code Skills 官方文档](https://docs.claude.com/en/docs/claude-code/skills)
- [api.md 命令文档](../../commands/api.md)
- [完整 Skill 文档](SKILL.md)
- [使用示例](EXAMPLES.md)
- [测试指南](TEST.md)

---

**版本**: 3.0.0 (最新)
**最后更新**: 2025-11-01
**作者**: AI Assistant

### 版本历史

- **v3.0.0** (2025-11-01) - 新增 `claude-api-use.sh`，直接修改 settings.json
- **v2.0.0** - 新增 `claude-api-restart.sh`
- **v1.0.0** - 初始版本，基本 CRUD 功能

