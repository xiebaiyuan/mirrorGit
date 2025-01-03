# GitHub to Gitea Mirror Script

这是一个自动将 GitHub 仓库镜像到 Gitea 的 Shell 脚本。支持批量同步所有仓库，可以设置跳过特定仓库，并具有良好的错误处理机制。

## 功能特性

- 自动同步 GitHub 所有仓库到 Gitea
- 支持设置跳过特定仓库
- 分级推送策略（先尝试 mirror，失败后逐个推送分支）
- 详细的进度显示和错误提示
- 支持通过环境变量配置
- 适合配合 crontab 使用
- 支持运行后收集报告并发送邮件

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

### 直接运行

```bash
GITHUB_USER=username \
GITHUB_TOKEN=your-github-token \
GITEA_URL=https://git.example.com \
GITEA_USER=username \
GITEA_TOKEN=your-gitea-token \
bash mirror.sh
```

### 配置环境变量后运行

```bash
# 设置环境变量
export GITHUB_USER=username
export GITHUB_TOKEN=your-github-token
export GITEA_URL=https://git.example.com
export GITEA_USER=username
export GITEA_TOKEN=your-gitea-token

# 运行脚本
bash mirror.sh
```

### 设置定时任务

编辑 crontab：
```bash
crontab -e
```

添加定时任务（每天凌晨 2 点运行）：
```cron
0 2 * * * GITHUB_USER=username GITHUB_TOKEN=xxx GITEA_URL=https://git.example.com GITEA_USER=username GITEA_TOKEN=xxx /path/to/mirror.sh >> /path/to/mirror.log 2>&1
```

### 跳过特定仓库

```bash
GITHUB_USER=username \
GITEA_URL=https://git.example.com \
GITEA_USER=username \
GITEA_TOKEN=xxx \
SKIP_REPOS="repo1,repo2,repo3" \
bash mirror.sh
```

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
bash mirror.sh
```

### Crontab 配置示例
```bash
0 2 * * * GITHUB_USER=username GITHUB_TOKEN=xxx GITEA_URL=https://git.example.com GITEA_USER=username GITEA_TOKEN=xxx SMTP_SERVER=smtp.gmail.com SMTP_PORT=587 SMTP_USER=your-email@gmail.com SMTP_PASS=your-password MAIL_TO=your-email@example.com /path/to/mirror.sh
```

## 常见问题

1. **获取 GitHub Token**
   - 访问 GitHub Settings -> Developer settings -> Personal access tokens
   - 创建新的 Token，至少需要 `repo` 权限

2. **获取 Gitea Token**
   - 访问 Gitea 设置 -> 应用 -> 创建新的令牌
   - 需要仓库的读写权限

4. **错误处理**
   - 检查令牌权限是否正确
   - 确保 Gitea 实例可访问
   - 验证用户名和 URL 是否正确

5. 调试模式

添加 `-x` 参数启用调试模式：
```bash
bash -x mirror.sh
```

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