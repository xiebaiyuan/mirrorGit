# GitHub Actions Secrets 配置示例

## 🔧 必需的 Secrets 配置

复制以下配置到您的 GitHub 仓库 Secrets 中：

### 基础配置
```
Secret 名称: GH_USER
Secret 值: your-github-username

Secret 名称: GH_TOKEN  
Secret 值: ghp_xxxxxxxxxxxxxxxxxxxx

Secret 名称: GITEA_URL
Secret 值: https://git.example.com:3000

Secret 名称: GITEA_USER
Secret 值: your-gitea-username

Secret 名称: GITEA_TOKEN
Secret 值: your-gitea-token-here
```

## 📧 邮件通知配置（可选）

如果要启用邮件通知，添加以下 Secrets：

```
Secret 名称: ENABLE_MAIL
Secret 值: true

Secret 名称: SMTP_SERVER
Secret 值: smtp.gmail.com

Secret 名称: SMTP_PORT
Secret 值: 587

Secret 名称: SMTP_USER
Secret 值: your-email@gmail.com

Secret 名称: SMTP_PASS
Secret 值: your-app-password

Secret 名称: MAIL_TO
Secret 值: admin@example.com

Secret 名称: MAIL_FROM
Secret 值: noreply@example.com
```

## 📱 飞书通知配置（可选）

如果要启用飞书通知，添加以下 Secrets：

```
Secret 名称: ENABLE_FEISHU
Secret 值: true

Secret 名称: FEISHU_WEBHOOK_URL
Secret 值: https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxxxx
```

## 🚫 跳过仓库配置（可选）

如果要跳过某些仓库，添加：

```
Secret 名称: SKIP_REPOS
Secret 值: archive,backup,test-repo,private-notes
```

### 📋 SKIP_REPOS 配置详解

**格式规则**:
- 仅使用仓库名称（不是完整路径）
- 用逗号分隔多个仓库
- 支持前后空格（会自动清理）
- 精确匹配仓库名称

**正确示例**:
```bash
# 基本格式
archive,backup,test

# 带空格（推荐，更易读）
archive, backup, test-repo, private-notes

# 单个仓库
archive
```

**错误示例**:
```bash
# ❌ 不要使用完整路径
username/archive,username/backup

# ❌ 不要使用URL
github.com/username/archive

# ❌ 不要使用通配符
test-*,*-backup
```

**实际案例**:
假设您有以下仓库要跳过：
- `mirrorGit-archive`
- `backup-2024`  
- `test-sandbox`
- `personal-notes`

配置为：
```
mirrorGit-archive, backup-2024, test-sandbox, personal-notes
```

## ⚠️ 重要注意事项

1. **Secret 名称限制**: GitHub 不允许 Secret 名称以 `GITHUB_` 开头
   - ❌ 错误: `GITHUB_USER`, `GITHUB_TOKEN`
   - ✅ 正确: `GH_USER`, `GH_TOKEN`

2. **URL 格式**: 
   - 支持端口: `https://git.example.com:3000`
   - 标准端口: `https://git.example.com`
   - 末尾不要加斜杠

3. **Token 权限**: 
   - GitHub Token 需要 `repo` 权限
   - Gitea Token 需要仓库读写权限

## 🔗 配置步骤

1. 进入您的 GitHub 仓库
2. 点击 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret`
4. 输入 Secret 名称和值
5. 点击 `Add secret`
6. 重复步骤 3-5 添加所有必需的 Secrets

配置完成后，GitHub Actions 将自动每天执行同步任务！