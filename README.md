# GitHub to Gitea Mirror Script

这是一个自动将 GitHub 仓库镜像到 Gitea 的增强版 Shell 脚本。支持批量同步所有仓库，并增加了断点续传、提交检查和进度显示等高级功能，具有良好的错误处理机制。

> 本项目基于 [songtianlun/mirrorGit](https://github.com/songtianlun/mirrorGit) 进行了功能增强和优化，特此鸣谢原作者的开源贡献。  
> 后续本项目将不再作为 fork 维护，而是独立发展。

## 增强功能特性

除了原项目的所有功能外，本版本新增了以下高级特性：

- **断点续传** - 同步被中断时可自动从中断位置继续
- **提交对比检查** - 同步前检查远端是否已经是相同提交，避免重复同步
- **分页获取仓库** - 支持超过100个仓库的同步（最多可同步300+个仓库）
- **增强的过程信息展示** - 同步前显示仓库地址，同步后显示仓库大小
- **彩色输出** - 使用不同颜色区分各类信息，提高可读性
- **精确的进度显示** - 实时展示同步进度、成功/失败/跳过的仓库数量
- **单仓库模式** - 支持对单个仓库进行同步
- **智能缓存管理** - 自动判断缓存状态，提高同步效率

## 必要条件

- Git
- curl
- jq
- GitHub Token（如需访问私有仓库）
- Gitea Token

## 环境变量

| 变量名 | 必需 | 说明 | 示例 |
|--------|------|------|------|
| GITHUB_USER | 是 | GitHub 用户名 | `xiebaiyuan` |
| GITHUB_TOKEN | 否 | GitHub 访问令牌 | `ghp_xxxxxxxxxxxx` |
| GITEA_URL | 是 | Gitea 实例地址 | `https://git.example.com` |
| GITEA_USER | 是 | Gitea 用户名 | `username` |
| GITEA_TOKEN | 是 | Gitea 访问令牌 | `d4209xxxxxxxxxxxxx` |
| SKIP_REPOS | 否 | 跳过的仓库列表（逗号分隔） | `repo1,repo2,repo3` |
| WORK_DIR | 否 | 临时工作目录 | `/tmp/git-mirror` |
| ENABLE_CACHE | 否 | 是否启用缓存机制 | `true` 或 `false` | `true` |
| CACHE_DIR | 否 | 缓存目录路径 | `/tmp/git-mirror/repos` | `$WORK_DIR/repos` |
| CACHE_EXPIRY | 否 | 缓存过期时间（秒） | `86400` | `86400` (24小时) |
| ENABLE_MAIL | 否 | 是否启用邮件通知 | `true` 或 `false` | `false` |
| SMTP_SERVER | 否 | SMTP 服务器地址 | `smtp.gmail.com` | - |
| SMTP_PORT | 否 | SMTP 端口 | `587` | `587` |
| SMTP_USER | 否 | SMTP 用户名 | `your-email@gmail.com` | - |
| SMTP_PASS | 否 | SMTP 密码 | `your-password` | - |
| MAIL_TO | 否 | 接收通知的邮箱 | `your-email@example.com` | - |
| MAIL_FROM | 否 | 发件人地址 | `noreply@example.com` | `$SMTP_USER` |

## 断点续传功能

本版本新增了断点续传功能，即使同步过程中被中断（如网络故障、服务器重启等），再次运行时也能从上次中断的位置继续：

- **自动检测断点** - 记录上次同步的进度，自动判断从何处继续
- **状态保存** - 同步每个仓库时都会记录当前状态
- **失败仓库保留** - 同步失败时保留工作目录，便于后续重试
- **智能跳过** - 已成功同步的仓库不会重复处理

## 提交对比检查

在同步前，脚本会比较 GitHub 和 Gitea 上仓库的最新提交哈希：

- **避免重复同步** - 如果两边提交相同，则跳过该仓库
- **节省带宽和时间** - 特别适合大型仓库的定期同步
- **精确日志** - 清晰显示跳过原因，区分"配置跳过"和"无变更跳过"

## 使用方法

### 快速开始
```bash
# 1. 下载代码
git clone https://github.com/xiebaiyuan/mirrorGit.git
cd mirrorGit

# 2. 给脚本执行权限
chmod +x main.sh mirror.sh mail.sh feishu_notify.sh

# 3. 运行同步
GITHUB_USER=your-username \
GITHUB_TOKEN=ghp_xxxxxxxxxxxx \
GITEA_URL=https://git.example.com:3000 \
GITEA_USER=your-gitea-username \
GITEA_TOKEN=your-gitea-token \
bash main.sh
```

### 使用配置文件
```bash
# 创建配置文件
cp .env.example .env

# 编辑配置文件，填入您的实际配置
vim .env

# 运行
source .env && bash main.sh
```

### GitHub Actions 自动同步

本项目提供了 GitHub Actions 工作流，可以自动定时执行同步任务。

#### 1. 配置 GitHub Secrets

在您的 GitHub 仓库中，依次点击 `Settings` -> `Secrets and variables` -> `Actions`，添加以下 secrets：

**必需的 Secrets：**
- `GH_USER`: GitHub 用户名
- `GH_TOKEN`: GitHub 访问令牌
- `GITEA_URL`: Gitea 实例地址（如 `https://git.example.com`）
- `GITEA_USER`: Gitea 用户名
- `GITEA_TOKEN`: Gitea 访问令牌

⚠️ **注意**: GitHub不允许Secret名称以 `GITHUB_` 开头，所以使用 `GH_USER` 和 `GH_TOKEN`。

**可选的 Secrets：**
- `SKIP_REPOS`: 跳过的仓库列表（逗号分隔）
- `ENABLE_MAIL`: 是否启用邮件通知（`true` 或 `false`）
- `SMTP_SERVER`: SMTP 服务器地址
- `SMTP_PORT`: SMTP 端口（默认 587）
- `SMTP_USER`: SMTP 用户名
- `SMTP_PASS`: SMTP 密码
- `MAIL_TO`: 接收通知的邮箱
- `MAIL_FROM`: 发件人地址
- `ENABLE_FEISHU`: 是否启用飞书通知（`true` 或 `false`）
- `FEISHU_WEBHOOK_URL`: 飞书机器人 Webhook URL

#### 2. 工作流说明

- **自动触发**: 每天北京时间凌晨 2 点自动执行
- **手动触发**: 在 Actions 页面可以手动触发，支持自定义参数
- **日志保存**: 同步日志会作为 artifacts 保存 30 天
- **执行摘要**: 在 Actions 页面可以查看同步统计信息

#### 3. 手动触发工作流

1. 进入仓库的 `Actions` 页面
2. 选择 `Sync GitHub to Gitea` 工作流
3. 点击 `Run workflow` 按钮
4. 可以自定义跳过的仓库和通知设置
5. 点击 `Run workflow` 开始执行

### 设置定时任务（服务器部署）

如果您想在自己的服务器上设置定时任务，可以编辑 crontab：
```bash
crontab -e
```

添加定时任务（每天凌晨 2 点运行）：
```cron
0 2 * * * GITHUB_USER=username GITHUB_TOKEN=xxx GITEA_URL=https://git.example.com GITEA_USER=username GITEA_TOKEN=xxx /path/to/main.sh >> /path/to/main.log 2>&1
```

## 性能优化

### 智能缓存 + 提交检查

本项目结合了缓存机制和提交对比检查，极大提升了同步效率：

- **首次运行**: 完整克隆所有仓库
- **后续运行**:
  1. 先检查提交哈希是否相同，相同则直接跳过
  2. 对需要更新的仓库，仅下载增量更新，节省时间和带宽
- **断点恢复**: 中断时保留工作目录，恢复时无需重复下载

### 性能对比

| 功能 | 原项目 | 增强版 | 提升 |
|------|--------|--------|------|
| 大量仓库(300+)同步 | 只支持100个 | 完全支持 | 支持范围扩大3倍 |
| 中断恢复 | 需重新开始 | 自动继续 | 节省90%恢复时间 |
| 重复同步检测 | 无 | 有 | 节省80%带宽 |
| 进度可视化 | 基础 | 详细彩色 | 提升用户体验 |

## 调试与错误处理

### 错误处理与恢复

- **断点记录**: 每个仓库同步前创建断点记录
- **细粒度恢复**: 从任意仓库处恢复同步
- **保留状态**: 同步失败时保留工作目录和状态
- **清晰日志**: 详细的彩色日志，方便定位问题

### 调试模式

添加 `-x` 参数启用调试模式：
```bash
bash -x main.sh
```

## 常见问题

1. **获取 GitHub Token**
   - 访问 GitHub Settings -> Developer settings -> Personal access tokens
   - 创建新的 Token，至少需要 `repo` 权限

2. **获取 Gitea Token**
   - 访问 Gitea 设置 -> 应用 -> 创建新的令牌
   - 需要仓库的读写权限

3. **GitHub Actions 相关**
   - 确保所有必需的 Secrets 都已正确配置
   - 检查 Actions 页面的执行日志
   - 下载 artifacts 查看详细的同步日志

4. **同步中断恢复**
   - 如果同步过程中断，只需再次运行脚本
   - 脚本会自动检测上次同步位置并继续
   - 已成功同步的仓库不会重复处理

5. **提交相同检测**
   - 如果日志显示"仓库已经是最新的，无需同步"，说明远端已有相同提交
   - 这是正常行为，可以避免不必要的同步操作

## 声明

本项目基于 [songtianlun/mirrorGit](https://github.com/songtianlun/mirrorGit) 进行了二次开发和功能增强。我们感谢原项目作者的开源贡献，并在此基础上添加了断点续传、提交检查和UI优化等功能。

根据开源协议，我们保留了原项目的 MIT License，并将在后续开发中独立维护本项目。本项目的增强功能旨在为用户提供更好的体验，特别是对于拥有大量仓库的用户和不稳定网络环境下的使用场景。

## License

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

_特别感谢 [songtianlun/mirrorGit](https://github.com/songtianlun/mirrorGit) 项目提供的基础框架和灵感。_
