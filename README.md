# GitHub to Gitea Mirror Script

这是一个自动将 GitHub 仓库镜像到 Gitea 的 Shell 脚本。支持批量同步所有仓库，可以设置跳过特定仓库，并具有良好的错误处理机制。

## 功能特性

- 自动同步 GitHub 所有仓库到 Gitea
- **智能缓存机制** - 大幅提升同步效率，避免重复下载
- 支持设置跳过特定仓库
- 分级推送策略（先尝试 mirror，失败后逐个推送分支）
- 详细的进度显示和错误提示
- 支持通过环境变量配置
- 适合配合 crontab 使用
- 支持运行后收集报告并发送邮件
- **GitHub Actions 集成** - 免服务器自动同步

## 必要条件

- Git
- curl
- jq
- GitHub Token（如需访问私有仓库）
- Gitea Token

## 环境变量

| 变量名 | 必需 | 说明 | 示例 |
|--------|------|------|------|
| GITHUB_USER | 是 | GitHub 用户名 | `songtianlun` |
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

## 日志文件

脚本会自动创建日志文件，包含完整的运行记录：

- 默认日志目录：`/tmp/github-mirror-logs`
- 日志文件名格式：`mirror-YYYYMMDD-HHMMSS.log`
- 每次运行创建新的日志文件

## 使用方法

### GitHub Actions 自动同步（推荐）

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

### 本地直接运行

#### 环境要求
```bash
# 安装必需依赖
# macOS
brew install git curl jq

# Ubuntu/Debian  
sudo apt-get install -y git curl jq

# CentOS/RHEL
sudo yum install -y git curl jq
```

#### 快速开始
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

#### 使用配置文件
```bash
# 创建配置文件
cp .env.example .env

# 编辑配置文件，填入您的实际配置
vim .env

# 运行
source .env && bash main.sh
```

详细本地使用说明请参考 [本地使用指南](LOCAL_USAGE.md)。

### 配置环境变量后运行

```bash
# 设置环境变量
export GITHUB_USER=your-username
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx
export GITEA_URL=https://git.example.com:3000
export GITEA_USER=your-gitea-username  
export GITEA_TOKEN=your-gitea-token
export SKIP_REPOS="archive,backup,test"

# 运行脚本
bash main.sh
```

### 设置定时任务（服务器部署）

如果您想在自己的服务器上设置定时任务，可以编辑 crontab：
```bash
crontab -e
```

添加定时任务（每天凌晨 2 点运行）：
```cron
0 2 * * * GITHUB_USER=username GITHUB_TOKEN=xxx GITEA_URL=https://git.example.com GITEA_USER=username GITEA_TOKEN=xxx /path/to/main.sh >> /path/to/main.log 2>&1
```

### 跳过特定仓库

```bash
GITHUB_USER=username \
GITEA_URL=https://git.example.com \
GITEA_USER=username \
GITEA_TOKEN=xxx \
SKIP_REPOS="archive,backup,test-repo" \
bash main.sh
```

**SKIP_REPOS 格式说明**:
- 仅使用仓库名称（如 `repo1,repo2,repo3`）
- 不要使用完整路径（如 `username/repo1`）
- 支持空格分隔（如 `repo1, repo2, repo3`）
- 精确匹配仓库名称

## 邮件通知配置

脚本支持在运行完成后发送邮件通知，需要配置以下环境变量：

| 变量名 | 必需 | 说明 | 示例 |
|--------|------|------|------|
| SMTP_SERVER | 否 | SMTP 服务器地址 | `smtp.gmail.com` |
| SMTP_PORT | 否 | SMTP 端口 | `587` |
| SMTP_USER | 否 | SMTP 用户名 | `your-email@gmail.com` |
| SMTP_PASS | 否 | SMTP 密码 | `your-password` |
| MAIL_TO | 否 | 接收通知的邮箱 | `your-email@example.com` |
| MAIL_FROM | 否 | 发件人地址（默认为 SMTP_USER） | `noreply@example.com` |

### 邮件通知使用示例

### 完整配置示例
```bash
GITHUB_USER=username \
GITHUB_TOKEN=xxx \
GITEA_URL=https://git.example.com \
GITEA_USER=username \
GITEA_TOKEN=xxx \
SMTP_SERVER=smtp.gmail.com \
SMTP_PORT=587 \
SMTP_USER=your-email@gmail.com \
SMTP_PASS=your-password \
MAIL_TO=your-email@example.com \
bash main.sh
```

### Crontab 配置示例
```bash
0 2 * * * GITHUB_USER=username GITHUB_TOKEN=xxx GITEA_URL=https://git.example.com GITEA_USER=username GITEA_TOKEN=xxx SMTP_SERVER=smtp.gmail.com SMTP_PORT=587 SMTP_USER=your-email@gmail.com SMTP_PASS=your-password MAIL_TO=your-email@example.com /path/to/main.sh
```

## 部署方式

### 方式一：GitHub Actions（推荐）

- ✅ 无需服务器，完全托管
- ✅ 定时自动执行
- ✅ 可视化日志和统计
- ✅ 支持手动触发
- ✅ 日志文件自动保存

配置简单，只需要在 GitHub 仓库中设置 Secrets 即可。详见上面的 "GitHub Actions 自动同步" 部分。

### 方式二：服务器部署

- ✅ 完全控制执行环境
- ✅ 可以自定义更复杂的逻辑
- ❌ 需要维护服务器
- ❌ 需要手动配置定时任务

适合有自己服务器且需要更多自定义的用户。详见上面的 "设置定时任务（服务器部署）" 部分。

## 💡 性能优化

### 缓存机制

本项目支持智能缓存，大幅提升同步效率：

- **首次运行**: 完整克隆所有仓库
- **后续运行**: 仅下载增量更新，节省时间和带宽
- **自动管理**: GitHub Actions 自动处理缓存存储和恢复

详细说明请参考 [缓存机制文档](CACHE.md)。

### 性能对比

| 场景 | 无缓存 | 有缓存 | 节省 |
|------|--------|--------|------|
| 10个仓库首次同步 | 5分钟 | 5分钟 | 0% |
| 10个仓库日常同步 | 5分钟 | 30秒 | 90% |
| 网络流量 | 每次1GB+ | 首次1GB+，后续<50MB | 95% |

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
   - 如果同步失败，可以手动触发工作流进行调试

4. **错误处理**
   - 检查令牌权限是否正确
   - 确保 Gitea 实例可访问
   - 验证用户名和 URL 是否正确

5. 调试模式

添加 `-x` 参数启用调试模式：
```bash
bash -x main.sh
```

### GitHub Actions 调试

如果 GitHub Actions 执行失败：

1. 检查 Actions 页面的执行日志
2. 下载 artifacts 中的详细日志文件
3. 验证所有 Secrets 配置是否正确
4. 使用手动触发功能进行测试
5. 检查 GitHub Token 和 Gitea Token 的权限

## 注意事项

- 建议使用专门的目录存放脚本和日志
- 定期检查日志确保同步正常
- 谨慎保管 Token，不要泄露
- 建议先使用测试账号验证配置
- 大型仓库同步可能需要较长时间

## License

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=songtianlun/mirrorGit&type=Timeline)](https://www.star-history.com/#songtianlun/mirrorGit&Timeline)
