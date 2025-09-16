# GitHub Actions 配置指南

本文档详细介绍如何配置和使用GitHub Actions来自动同步GitHub仓库到Gitea。

## 🚀 快速开始

### 1. Fork或下载本仓库

将本仓库Fork到您的GitHub账户，或者下载代码后创建新的仓库。

### 2. 配置Secrets

在您的GitHub仓库中配置以下Secrets：

**Settings** → **Secrets and variables** → **Actions** → **New repository secret**

## 📝 必需的Secrets配置

| Secret名称 | 说明 | 示例 |
|-----------|------|------|
| `GH_USER` | 您的GitHub用户名 | `your-username` |
| `GH_TOKEN` | GitHub个人访问令牌 | `ghp_xxxxxxxxxxxx` |
| `GITEA_URL` | Gitea实例的完整URL（支持自定义端口） | `https://git.example.com:3000` 或 `https://git.example.com` |
| `GITEA_USER` | Gitea用户名 | `your-gitea-username` |
| `GITEA_TOKEN` | Gitea访问令牌 | `abcdef123456789` |

⚠️ **重要提示**: GitHub不允许Secret名称以 `GITHUB_` 开头，所以我们使用 `GH_USER` 和 `GH_TOKEN` 代替。

### GITEA_URL 格式说明

`GITEA_URL` 支持多种格式：

- **标准HTTPS端口**: `https://git.example.com`
- **自定义端口**: `https://git.example.com:3000`
- **HTTP协议**: `http://git.example.com:3000`
- **IP地址**: `https://192.168.1.100:3000`
- **本地地址**: `http://localhost:3000`

⚠️ **注意**: 
- URL末尾不要添加斜杠 `/`
- 确保协议（http/https）与实际服务配置匹配
- 如果使用自签名证书，可能需要额外配置

## 🔧 可选的Secrets配置

### 基础配置

| Secret名称 | 说明 | 默认值 | 示例 |
|-----------|------|--------|------|
| `SKIP_REPOS` | 跳过同步的仓库（逗号分隔） | 空 | `repo1,repo2,archive` |

### 邮件通知配置

| Secret名称 | 说明 | 默认值 | 示例 |
|-----------|------|--------|------|
| `ENABLE_MAIL` | 是否启用邮件通知 | `false` | `true` |
| `SMTP_SERVER` | SMTP服务器地址 | 空 | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP端口 | `587` | `587` |
| `SMTP_USER` | SMTP用户名 | 空 | `your-email@gmail.com` |
| `SMTP_PASS` | SMTP密码或应用专用密码 | 空 | `your-password` |
| `MAIL_TO` | 接收通知的邮箱 | 空 | `admin@example.com` |
| `MAIL_FROM` | 发件人地址 | `$SMTP_USER` | `noreply@example.com` |

### 飞书通知配置

| Secret名称 | 说明 | 默认值 | 示例 |
|-----------|------|--------|------|
| `ENABLE_FEISHU` | 是否启用飞书通知 | `false` | `true` |
| `FEISHU_WEBHOOK_URL` | 飞书机器人Webhook URL | 空 | `https://open.feishu.cn/open-apis/bot/v2/hook/xxx` |

## 🎯 获取Token指南

### GitHub Token

1. 登录GitHub，进入 **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. 点击 **Generate new token** → **Generate new token (classic)**
3. 设置有效期并选择以下权限：
   - `repo` (完整的仓库访问权限)
   - `read:user` (读取用户基本信息)
4. 生成后复制Token（只显示一次）
5. 在GitHub仓库Secrets中配置为 `GH_TOKEN`（不是 `GITHUB_TOKEN`）

### Gitea Token

1. 登录您的Gitea实例
2. 进入用户设置 → **应用** → **管理访问令牌**
3. 点击 **生成新的令牌**
4. 选择权限（建议选择`repo`相关权限）
5. 生成后复制Token

## ⚡ 工作流功能

### 自动触发

- **定时执行**: 每天北京时间凌晨2点（UTC 18:00）自动执行
- **代码更新**: 当推送代码到main分支时也会触发

### 手动触发

1. 进入仓库的 **Actions** 页面
2. 选择 **Sync GitHub to Gitea** 工作流
3. 点击 **Run workflow** 按钮
4. 可以自定义以下参数：
   - 跳过的仓库列表
   - 是否启用邮件通知
   - 是否启用飞书通知
5. 点击 **Run workflow** 开始执行

### 查看结果

执行完成后，您可以：

1. **查看摘要**: 在Actions运行页面查看同步统计信息
2. **下载日志**: 点击artifacts下载完整的同步日志
3. **接收通知**: 如果配置了邮件或飞书通知，会收到详细的同步报告

## 🔍 调试指南

### 常见问题排查

1. **工作流执行失败**
   - 检查所有必需的Secrets是否已配置
   - 验证Token是否有效且权限正确
   - 查看Actions执行日志中的错误信息

2. **同步失败**
   - 下载artifacts中的详细日志
   - 检查Gitea实例是否可访问
   - 验证仓库权限设置

3. **通知功能不工作**
   - 确认已启用对应的通知功能
   - 检查SMTP或飞书配置是否正确
   - 查看日志中的通知发送状态

### 测试配置

建议先使用测试配置验证：

1. 创建测试用的GitHub和Gitea账户
2. 配置较少的仓库进行测试
3. 启用详细日志查看执行过程
4. 验证通知功能是否正常

## 📊 监控和维护

### 定期检查

建议定期检查以下内容：

- [ ] GitHub Actions的执行状态
- [ ] Token的有效期（GitHub Token通常有过期时间）
- [ ] 同步统计数据是否正常
- [ ] 日志中是否有异常信息

### 更新维护

- Token过期时及时更新Secrets
- 根据需要调整跳过的仓库列表
- 定期清理不需要的同步日志

## 🔒 安全建议

1. **Token管理**
   - 使用最小权限原则配置Token
   - 定期轮换Token
   - 不要在代码中硬编码Token

2. **仓库权限**
   - 限制谁可以修改仓库Secrets
   - 定期审查访问权限
   - 使用分支保护规则

3. **通知配置**
   - 邮件通知建议使用应用专用密码
   - 飞书机器人配置IP白名单（如果支持）

## 🤝 贡献

如果您在使用过程中遇到问题或有改进建议，欢迎：

- 提交Issue报告问题
- 发起Pull Request改进代码
- 分享使用经验和最佳实践

## 📚 相关链接

- [GitHub Actions文档](https://docs.github.com/en/actions)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Gitea API文档](https://docs.gitea.io/en-us/api-usage/)