# 安全配置指南

本文档说明如何安全地配置和使用GitHub到Gitea同步脚本。

## 🔒 敏感信息保护

### .env 文件
项目已创建 `.gitignore` 文件，以下文件不会被提交到版本控制：
- `.env` - 您的实际配置文件
- `.env.local` - 本地配置
- `*.log` - 日志文件
- `/tmp/` - 临时文件

### 配置步骤
1. **复制示例配置**
   ```bash
   cp .env.example .env
   ```

2. **编辑配置文件**
   ```bash
   vim .env  # 填入您的实际Token和配置
   ```

3. **验证权限**
   ```bash
   chmod 600 .env  # 确保只有您可以读写
   ```

## 🔑 Token 安全最佳实践

### GitHub Token
1. **权限最小化**
   - 只授予必要的 `repo` 权限
   - 避免授予管理员权限

2. **定期轮换**
   - 建议每3-6个月更换Token
   - 如果怀疑泄露，立即撤销并重新生成

3. **监控使用**
   - 定期检查Token使用情况
   - 关注异常的API调用

### Gitea Token
1. **范围限制**
   - 只授予仓库读写权限
   - 不要授予用户管理权限

2. **访问控制**
   - 配置IP白名单（如果Gitea支持）
   - 使用专用账户而非个人账户

## 🖥️ 服务器安全

### 文件权限
```bash
# 设置正确的文件权限
chmod 700 /path/to/mirrorGit     # 目录权限
chmod 600 .env                   # 配置文件权限
chmod 755 *.sh                   # 脚本执行权限
```

### 日志安全
```bash
# 设置日志目录权限
mkdir -p /var/log/github-mirror
chmod 750 /var/log/github-mirror
chown $(whoami):$(whoami) /var/log/github-mirror
```

### 定时任务安全
```bash
# crontab 示例 - 使用绝对路径
0 2 * * * cd /home/user/mirrorGit && /bin/bash -c 'source .env && ./main.sh' >> /var/log/github-mirror/sync.log 2>&1
```

## 🔍 安全检查清单

### 部署前检查
- [ ] `.env` 文件权限设置正确（600）
- [ ] Token权限最小化
- [ ] 配置文件不在版本控制中
- [ ] 日志目录权限正确
- [ ] 脚本文件权限正确

### 运行时监控
- [ ] 定期检查日志异常
- [ ] 监控Token使用情况
- [ ] 验证同步结果
- [ ] 检查Gitea存储使用

### 定期维护
- [ ] 更新Token（3-6个月）
- [ ] 清理旧日志文件
- [ ] 更新跳过仓库列表
- [ ] 检查依赖更新

## 🚨 紧急响应

### Token泄露处理
1. **立即撤销**
   ```bash
   # 在GitHub/Gitea中立即撤销Token
   ```

2. **生成新Token**
   ```bash
   # 生成新Token并更新 .env 文件
   ```

3. **检查日志**
   ```bash
   # 检查是否有异常使用
   grep "ERROR\|FAIL" /var/log/github-mirror/*.log
   ```

### 异常检测
```bash
# 监控脚本
#!/bin/bash
LOG_FILE="/var/log/github-mirror/latest.log"

# 检查错误
if grep -q "Failed\|Error\|403\|401" "$LOG_FILE"; then
    echo "检测到同步错误，请检查日志" | mail -s "同步警告" admin@example.com
fi

# 检查Token过期
if grep -q "Bad credentials" "$LOG_FILE"; then
    echo "Token可能已过期，请更新" | mail -s "Token过期" admin@example.com
fi
```

## 🌐 网络安全

### HTTPS配置
- 确保Gitea使用HTTPS
- 验证SSL证书有效性
- 使用强加密套件

### 防火墙规则
```bash
# 只允许必要的出站连接
# GitHub API: api.github.com:443
# Gitea: your-gitea-domain:port
```

### 代理配置（如需要）
```bash
export https_proxy=http://proxy.company.com:8080
export http_proxy=http://proxy.company.com:8080
```

## 📝 审计和合规

### 操作日志
- 保留同步操作日志
- 记录配置变更
- 监控访问模式

### 合规检查
- 确保符合数据保护法规
- 验证跨境数据传输合规性
- 定期安全审计

### 备份策略
```bash
# 定期备份配置
cp .env .env.backup.$(date +%Y%m%d)

# 备份重要日志
tar -czf logs-backup-$(date +%Y%m%d).tar.gz /var/log/github-mirror/
```

## ⚡ 快速安全设置

### 一键安全配置
```bash
#!/bin/bash
# setup-security.sh

# 创建配置文件
cp .env.example .env
echo "请编辑 .env 文件并填入您的配置"

# 设置权限
chmod 600 .env
chmod 755 *.sh
chmod 700 .

# 创建日志目录
mkdir -p logs
chmod 750 logs

echo "安全配置完成！"
echo "下一步: 编辑 .env 文件并填入您的Token"
```

遵循这些安全最佳实践，确保您的同步过程安全可靠！