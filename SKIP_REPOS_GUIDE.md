# SKIP_REPOS 配置详细指南

## 📋 基本格式

### ✅ 正确格式
```bash
# 基本逗号分隔
SKIP_REPOS="repo1,repo2,repo3"

# 带空格（推荐，更易读）
SKIP_REPOS="archive, backup, test-repo, private-notes"

# 单个仓库
SKIP_REPOS="archive"

# 空值（不跳过任何仓库）
SKIP_REPOS=""
```

### ❌ 错误格式
```bash
# 不要使用完整GitHub路径
SKIP_REPOS="username/repo1,username/repo2"

# 不要使用URL
SKIP_REPOS="github.com/username/repo1"

# 不要使用通配符
SKIP_REPOS="test-*,*-backup"

# 不要使用仓库ID
SKIP_REPOS="123456,789012"
```

## 🎯 实际配置示例

### 场景1：跳过归档和备份仓库
```bash
SKIP_REPOS="archive, backup, old-project, deprecated"
```

### 场景2：跳过测试和临时仓库
```bash
SKIP_REPOS="test-sandbox, temp-repo, playground, experiments"
```

### 场景3：跳过大型仓库（节省时间）
```bash
SKIP_REPOS="large-dataset, video-files, binary-assets"
```

### 场景4：跳过私人笔记
```bash
SKIP_REPOS="personal-notes, diary, private-config"
```

## 🔧 在不同环境中配置

### 1. GitHub Actions Secrets
进入仓库设置：
```
Settings → Secrets and variables → Actions → New repository secret

名称: SKIP_REPOS
值: archive, backup, test-repo, private-notes
```

### 2. 手动触发GitHub Actions
在Actions页面点击 "Run workflow"：
```
跳过的仓库列表: archive, backup, test-repo
```

### 3. 本地运行
```bash
SKIP_REPOS="archive,backup,test" bash main.sh
```

### 4. 环境变量文件
```bash
# .env 文件
export SKIP_REPOS="archive, backup, test-repo"
```

## 🔍 如何确定要跳过的仓库

### 查看所有仓库列表
```bash
# 使用GitHub API获取仓库列表
curl -H "Authorization: token YOUR_TOKEN" \
  "https://api.github.com/user/repos?per_page=100" | \
  jq -r '.[].name' | sort
```

### 常见的跳过仓库类型

#### 📦 归档类
- `archive`
- `backup`
- `old-*`
- `deprecated`
- `legacy-*`

#### 🧪 测试类
- `test-*`
- `playground`
- `sandbox`
- `experiments`
- `demo-*`

#### 📝 文档类
- `docs`
- `wiki`
- `notes`
- `*.github.io` (GitHub Pages)

#### 🔒 私人类
- `personal-*`
- `private-*`
- `config`
- `dotfiles`

#### 💾 大文件类
- `datasets`
- `media-files`
- `binaries`
- `*-assets`

## 🎛️ 高级配置技巧

### 动态配置（基于分支）
```yaml
# 在GitHub Actions中
env:
  SKIP_REPOS: ${{ github.ref == 'refs/heads/main' && 'test,staging' || 'production' }}
```

### 按环境配置
```bash
# 开发环境 - 跳过生产相关
SKIP_REPOS="production, prod-config, live-data"

# 生产环境 - 跳过测试相关  
SKIP_REPOS="test, dev, staging, playground"
```

### 临时跳过大仓库
```bash
# 当网络慢时，临时跳过大仓库
SKIP_REPOS="large-repo1, video-assets, dataset-archive"
```

## 🚨 注意事项

### 1. 精确匹配
```bash
# 如果有仓库名为 "test" 和 "test-repo"
SKIP_REPOS="test"        # 只跳过 "test"
SKIP_REPOS="test-repo"   # 只跳过 "test-repo"
```

### 2. 大小写敏感
```bash
# 仓库名区分大小写
SKIP_REPOS="Archive"     # 不会跳过 "archive"
SKIP_REPOS="archive"     # 不会跳过 "Archive"
```

### 3. 空格处理
```bash
# 以下都是等效的
SKIP_REPOS="repo1,repo2,repo3"
SKIP_REPOS="repo1, repo2, repo3"  
SKIP_REPOS=" repo1 , repo2 , repo3 "
```

### 4. 特殊字符
```bash
# 如果仓库名包含特殊字符，直接使用
SKIP_REPOS="my-repo, repo_with_underscore, repo.with.dots"
```

## 📊 验证配置

### 查看同步日志
运行后查看日志确认跳过的仓库：
```
跳过仓库: archive
跳过仓库: backup
处理仓库: my-project
```

### 检查统计报告
在同步完成的JSON报告中：
```json
{
  "skipped": 2,
  "details": {
    "skipped_repos": ["archive", "backup"]
  }
}
```

## 🔄 动态调整

### 临时添加跳过仓库
如果发现某个仓库同步有问题，可以临时添加到跳过列表：
```bash
# 原配置
SKIP_REPOS="archive, backup"

# 临时添加问题仓库
SKIP_REPOS="archive, backup, problematic-repo"
```

### 批量测试
先用小范围测试：
```bash
# 只同步少数仓库进行测试
SKIP_REPOS="repo1,repo2,repo3,repo4,repo5"  # 跳过大部分，只保留1-2个测试
```

这样配置后，您就可以精确控制哪些仓库需要同步，哪些需要跳过了！