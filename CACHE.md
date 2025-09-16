# 缓存机制说明

本项目现在支持智能缓存机制，大幅提升同步效率，特别是对于大型仓库。

## 🚀 缓存机制优势

### 性能提升
- **首次运行**: 完整克隆所有仓库（耗时较长）
- **后续运行**: 
  - 缓存未过期：仅更新增量内容（快速）
  - 缓存已过期：重新克隆（根据设置）

### 节省资源
- **网络带宽**: 减少重复下载
- **存储空间**: GitHub Actions缓存自动管理
- **执行时间**: 大型仓库同步时间从分钟级别降到秒级

## ⚙️ 缓存配置

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `ENABLE_CACHE` | `true` | 是否启用缓存机制 |
| `CACHE_DIR` | `$WORK_DIR/repos` | 缓存目录路径 |
| `CACHE_EXPIRY` | `86400` | 缓存过期时间（秒），24小时 |

### 在GitHub Actions中配置

缓存已自动配置在workflow中，您可以通过Secrets调整：

```bash
# 可选配置
ENABLE_CACHE=true          # 启用缓存
CACHE_EXPIRY=43200         # 12小时过期
```

### 本地运行配置

```bash
# 启用缓存，12小时过期
ENABLE_CACHE=true \
CACHE_EXPIRY=43200 \
CACHE_DIR=/path/to/cache \
bash main.sh
```

## 🔄 缓存工作原理

### 1. 智能检查
```bash
# 检查仓库是否需要更新
├── 仓库不存在 → 完整克隆
├── 缓存过期 → 完整克隆  
└── 缓存有效 → 增量更新
```

### 2. 缓存策略
- **首次克隆**: `git clone --mirror` 获取完整仓库
- **增量更新**: `git remote update` 仅获取新的提交
- **过期重建**: 超过设定时间后重新完整克隆

### 3. GitHub Actions缓存
- **自动保存**: 每次运行后自动保存缓存
- **智能恢复**: 下次运行时自动恢复缓存
- **版本管理**: 支持基于用户和运行次数的缓存键

## 📊 性能对比

### 无缓存模式
```
仓库A (500MB) → 下载500MB → 2分钟
仓库B (1GB)   → 下载1GB   → 4分钟
仓库C (200MB) → 下载200MB → 1分钟
总计: 7分钟，1.7GB流量
```

### 缓存模式（首次）
```
仓库A (500MB) → 下载500MB → 2分钟
仓库B (1GB)   → 下载1GB   → 4分钟  
仓库C (200MB) → 下载200MB → 1分钟
总计: 7分钟，1.7GB流量（与无缓存相同）
```

### 缓存模式（后续）
```
仓库A → 增量更新 → 10秒
仓库B → 增量更新 → 15秒
仓库C → 增量更新 → 5秒
总计: 30秒，<10MB流量
```

## 🛠️ 缓存管理

### 查看缓存状态
```bash
# 查看缓存目录
ls -la /tmp/github-mirror/repos/

# 查看单个仓库缓存时间
cat /tmp/github-mirror/repos/repo-name/.last_sync
```

### 清理缓存
```bash
# 清理所有缓存
rm -rf /tmp/github-mirror/repos/

# 清理特定仓库缓存
rm -rf /tmp/github-mirror/repos/repo-name
```

### 强制重新克隆
```bash
# 临时禁用缓存
ENABLE_CACHE=false bash main.sh

# 或删除特定仓库缓存后运行
rm -rf /tmp/github-mirror/repos/repo-name
bash main.sh
```

## 🔧 高级配置

### 不同场景的缓存策略

#### 开发环境（频繁更新）
```bash
CACHE_EXPIRY=3600  # 1小时过期
```

#### 生产环境（稳定同步）
```bash
CACHE_EXPIRY=86400  # 24小时过期
```

#### 大型仓库优化
```bash
CACHE_EXPIRY=259200  # 3天过期，减少重新克隆
```

### GitHub Actions缓存限制

- **总容量**: 10GB per repository
- **单个缓存**: 建议<1GB，最大10GB
- **生命周期**: 7天未访问自动删除
- **并发**: 同时只能读写一个缓存

### 缓存键策略

当前使用的缓存键格式：
```yaml
key: mirror-repos-${{ secrets.GH_USER }}-${{ github.run_number }}
restore-keys: |
  mirror-repos-${{ secrets.GH_USER }}-
  mirror-repos-
```

这确保：
- 每个用户独立缓存
- 可以复用之前的缓存
- 支持跨分支共享

## ⚠️ 注意事项

### 适用场景
✅ **适合**: 
- 多个中小型仓库（<100MB each）
- 定期同步（天/周级别）
- 网络带宽有限

❌ **不适合**:
- 单个超大仓库（>1GB）
- 极高频率同步（分钟级别）
- 对实时性要求极高

### 故障排除

1. **缓存空间不足**
   - 减少缓存过期时间
   - 清理不需要的仓库缓存

2. **缓存损坏**
   ```bash
   # 清理并重新开始
   rm -rf /tmp/github-mirror/repos/
   ```

3. **同步失败**
   - 检查缓存目录权限
   - 验证网络连接
   - 查看详细日志

## 📈 监控缓存效果

同步报告中会显示缓存使用情况：
- 缓存命中的仓库数量
- 重新克隆的仓库数量  
- 总体时间节省

您可以在GitHub Actions的Summary中查看这些统计信息。