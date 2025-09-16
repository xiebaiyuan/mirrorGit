# 本地使用指南

本文档详细说明如何在本地环境中使用GitHub到Gitea同步脚本。

## 🛠️ 环境要求

### 必需依赖
确保您的系统已安装以下工具：

```bash
# macOS
brew install git curl jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git curl jq

# CentOS/RHEL
sudo yum install -y git curl jq

# Arch Linux
sudo pacman -S git curl jq
```

### 验证安装
```bash
git --version
curl --version
jq --version
```

## 📥 获取代码

### 方法1：克隆仓库
```bash
git clone https://github.com/xiebaiyuan/mirrorGit.git
cd mirrorGit
```

### 方法2：下载ZIP
```bash
# 下载并解压
wget https://github.com/xiebaiyuan/mirrorGit/archive/main.zip
unzip main.zip
cd mirrorGit-main
```

## 🔑 获取访问令牌

### GitHub Token
1. 登录GitHub → Settings → Developer settings → Personal access tokens
2. 点击 "Generate new token (classic)"
3. 选择权限：`repo`（完整仓库访问权限）
4. 复制生成的token（格式：`ghp_xxxxxxxxxxxx`）

### Gitea Token  
1. 登录您的Gitea实例
2. 用户设置 → 应用 → 管理访问令牌
3. 生成新的令牌，选择仓库权限
4. 复制生成的token

## 🚀 快速开始

### 基本使用
```bash
# 给脚本执行权限
chmod +x main.sh mirror.sh mail.sh feishu_notify.sh

# 运行同步
GITHUB_USER=your-username \
GITHUB_TOKEN=ghp_xxxxxxxxxxxx \
GITEA_URL=https://git.example.com:3000 \
GITEA_USER=your-gitea-username \
GITEA_TOKEN=your-gitea-token \
bash main.sh
```

### 使用环境变量文件
创建配置文件：
```bash
# 复制示例配置文件
cp .env.example .env

# 编辑配置文件，填入您的实际配置
vim .env  # 或使用您喜欢的编辑器
```

配置文件示例（`.env`）：
```bash
export GITHUB_USER="your-username"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export GITEA_URL="https://git.example.com:3000"
export GITEA_USER="your-gitea-username"  
export GITEA_TOKEN="your-gitea-token"
export SKIP_REPOS="archive,backup,test"
export ENABLE_CACHE="true"
```

然后运行：
```bash
source .env && bash main.sh
```

⚠️ **安全提示**: `.env` 文件包含敏感信息，已被添加到 `.gitignore` 中，不会提交到版本控制。

## ⚙️ 详细配置

### 必需配置
| 变量 | 说明 | 示例 |
|------|------|------|
| `GITHUB_USER` | GitHub用户名 | `xiebaiyuan` |
| `GITHUB_TOKEN` | GitHub访问令牌 | `ghp_xxxxxxxxxxxx` |
| `GITEA_URL` | Gitea实例地址 | `https://git.example.com:3000` |
| `GITEA_USER` | Gitea用户名 | `xiebaiyuan` |
| `GITEA_TOKEN` | Gitea访问令牌 | `abcdef123456` |

### 可选配置
| 变量 | 默认值 | 说明 |
|------|--------|------|
| `WORK_DIR` | `/tmp/github-mirror` | 工作目录 |
| `SKIP_REPOS` | 见config.sh | 跳过的仓库 |
| `ENABLE_CACHE` | `true` | 启用缓存 |
| `CACHE_EXPIRY` | `86400` | 缓存过期时间（秒） |
| `ENABLE_MAIL` | `false` | 启用邮件通知 |
| `ENABLE_FEISHU` | `false` | 启用飞书通知 |

## 📧 邮件通知配置

如需启用邮件通知：
```bash
export ENABLE_MAIL="true"
export SMTP_SERVER="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="your-email@gmail.com"
export SMTP_PASS="your-app-password"
export MAIL_TO="admin@example.com"
export MAIL_FROM="noreply@example.com"
```

### Gmail配置示例
```bash
# Gmail SMTP配置
export SMTP_SERVER="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="your-email@gmail.com"
export SMTP_PASS="your-app-password"  # 使用应用专用密码
```

## 📱 飞书通知配置

如需启用飞书通知：
```bash
export ENABLE_FEISHU="true"
export FEISHU_WEBHOOK_URL="https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxxxx"
```

## 🗂️ 使用示例

### 示例1：基本同步
```bash
#!/bin/bash
# sync.sh

GITHUB_USER="xiebaiyuan" \
GITHUB_TOKEN="ghp_xxxxxxxxxxxx" \
GITEA_URL="https://git.example.com:3000" \
GITEA_USER="xiebaiyuan" \
GITEA_TOKEN="your-gitea-token" \
bash main.sh
```

### 示例2：跳过特定仓库
```bash
GITHUB_USER="xiebaiyuan" \
GITHUB_TOKEN="ghp_xxxxxxxxxxxx" \
GITEA_URL="https://git.example.com" \
GITEA_USER="xiebaiyuan" \
GITEA_TOKEN="your-gitea-token" \
SKIP_REPOS="archive,backup,test-repo,private-notes" \
bash main.sh
```

### 示例3：完整配置
```bash
# 完整配置示例
GITHUB_USER="xiebaiyuan" \
GITHUB_TOKEN="ghp_xxxxxxxxxxxx" \
GITEA_URL="https://git.example.com:3000" \
GITEA_USER="xiebaiyuan" \
GITEA_TOKEN="your-gitea-token" \
WORK_DIR="/home/user/sync-workspace" \
SKIP_REPOS="archive,backup,test" \
ENABLE_CACHE="true" \
CACHE_EXPIRY="43200" \
ENABLE_MAIL="true" \
SMTP_SERVER="smtp.gmail.com" \
SMTP_PORT="587" \
SMTP_USER="your-email@gmail.com" \
SMTP_PASS="your-app-password" \
MAIL_TO="admin@example.com" \
bash main.sh
```

## 📋 定时任务配置

### 使用crontab
```bash
# 编辑crontab
crontab -e

# 添加定时任务（每天凌晨2点执行）
0 2 * * * cd /path/to/mirrorGit && source .env && bash main.sh >> /var/log/github-mirror.log 2>&1
```

### 创建定时脚本
```bash
#!/bin/bash
# /home/user/scripts/github-sync.sh

cd /path/to/mirrorGit

# 设置环境变量
export GITHUB_USER="xiebaiyuan"
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
export GITEA_URL="https://git.example.com:3000"
export GITEA_USER="xiebaiyuan"
export GITEA_TOKEN="your-gitea-token"
export SKIP_REPOS="archive,backup"

# 运行同步
bash main.sh

# 可选：发送完成通知
echo "同步完成: $(date)" | mail -s "GitHub同步完成" admin@example.com
```

然后设置定时：
```bash
chmod +x /home/user/scripts/github-sync.sh
crontab -e
# 添加：0 2 * * * /home/user/scripts/github-sync.sh
```

## 📊 查看运行结果

### 查看日志
```bash
# 实时查看日志
tail -f /tmp/github-mirror/logs/mirror-*.log

# 查看最新日志
ls -la /tmp/github-mirror/logs/
cat /tmp/github-mirror/logs/mirror-20240916-140530.log
```

### 查看统计信息
```bash
# 查看同步统计
cat /tmp/github-mirror/logs/sync_stats-20240916-140530.json | jq .
```

示例输出：
```json
{
  "total_repos": 15,
  "processed": 12,
  "skipped": 3,
  "success": 11,
  "failed": 1,
  "start_time": "2024-09-16 14:05:30",
  "end_time": "2024-09-16 14:08:45",
  "details": {
    "skipped_repos": ["archive", "backup", "test"],
    "success_repos": ["repo1", "repo2", "..."],
    "failed_repos": ["problematic-repo"]
  }
}
```

## 🔍 故障排除

### 常见问题

#### 1. 权限错误
```bash
# 确保脚本有执行权限
chmod +x main.sh mirror.sh mail.sh feishu_notify.sh
```

#### 2. 依赖缺失
```bash
# 检查依赖
which git curl jq
```

#### 3. Token权限不足
- 确保GitHub Token有`repo`权限
- 确保Gitea Token有仓库读写权限

#### 4. 网络问题
```bash
# 测试连接
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
curl -H "Authorization: token $GITEA_TOKEN" $GITEA_URL/api/v1/user
```

### 调试模式
```bash
# 启用详细输出
bash -x main.sh

# 或设置调试环境变量
DEBUG=1 bash main.sh
```

### 测试配置
```bash
# 先测试少数仓库
SKIP_REPOS="repo1,repo2,repo3,repo4" bash main.sh
```

## 💡 最佳实践

### 1. 安全
- 使用环境变量或配置文件存储敏感信息
- 不要在命令历史中暴露Token
- 定期轮换访问令牌

### 2. 性能
- 启用缓存机制减少下载时间
- 合理设置缓存过期时间
- 跳过不需要的大型仓库

### 3. 监控
- 设置邮件通知获取同步结果
- 定期检查同步日志
- 监控Gitea存储空间

### 4. 维护
- 定期清理工作目录
- 更新跳过仓库列表
- 检查Token有效期

现在您可以在本地轻松使用这个同步脚本了！