#!/bin/bash

# 参数获取
GITHUB_USER="$1"
GITHUB_TOKEN="$2"
GITEA_URL="$3"
GITEA_USER="$4"
GITEA_TOKEN="$5"
WORK_DIR="$6"
SKIP_REPOS="$7"
STATS_FILE="$8"

# 缓存配置
ENABLE_CACHE=${ENABLE_CACHE:-"false"}
CACHE_DIR=${CACHE_DIR:-"$WORK_DIR/repos"}
CACHE_EXPIRY=${CACHE_EXPIRY:-"86400"}  # 24小时，单位秒

# 检查仓库是否需要更新
need_update() {
    local repo="$1"
    local repo_path="$CACHE_DIR/$repo"
    
    # 如果禁用缓存，总是更新
    if [ "$ENABLE_CACHE" != "true" ]; then
        return 0  # 需要更新
    fi
    
    # 如果仓库不存在，需要更新
    if [ ! -d "$repo_path" ]; then
        echo "缓存中未找到仓库 $repo，需要克隆"
        return 0  # 需要更新
    fi
    
    # 检查缓存是否过期
    if [ -f "$repo_path/.last_sync" ]; then
        last_sync=$(cat "$repo_path/.last_sync")
        current_time=$(date +%s)
        time_diff=$((current_time - last_sync))
        
        if [ $time_diff -gt $CACHE_EXPIRY ]; then
            echo "仓库 $repo 缓存已过期（${time_diff}秒），需要更新"
            return 0  # 需要更新
        else
            echo "仓库 $repo 使用缓存（剩余 $((CACHE_EXPIRY - time_diff)) 秒）"
            return 1  # 不需要更新
        fi
    else
        echo "仓库 $repo 缓存信息缺失，需要更新"
        return 0  # 需要更新
    fi
}

# 克隆或更新仓库
clone_or_update_repo() {
    local repo="$1"
    local repo_path="$CACHE_DIR/$repo"
    
    if need_update "$repo"; then
        # 创建缓存目录
        mkdir -p "$CACHE_DIR"
        
        # 如果仓库已存在，先删除
        [ -d "$repo_path" ] && rm -rf "$repo_path"
        
        echo "克隆仓库 $repo..."
        if git clone --mirror "https://${GITHUB_TOKEN:+$GITHUB_TOKEN@}github.com/$GITHUB_USER/$repo.git" "$repo_path"; then
            # 记录同步时间
            date +%s > "$repo_path/.last_sync"
            echo "仓库 $repo 克隆完成"
            return 0
        else
            echo "仓库 $repo 克隆失败"
            return 1
        fi
    else
        # 使用缓存，但需要获取最新更改
        echo "更新缓存仓库 $repo..."
        cd "$repo_path"
        if git remote update; then
            # 更新同步时间
            date +%s > "$repo_path/.last_sync"
            echo "仓库 $repo 更新完成"
            cd - > /dev/null
            return 0
        else
            echo "仓库 $repo 更新失败"
            cd - > /dev/null
            return 1
        fi
    fi
}

# 初始化统计
init_stats() {
    cat > "$STATS_FILE" << EOF
{
    "total_repos": 0,
    "processed": 0,
    "skipped": 0,
    "success": 0,
    "failed": 0,
    "start_time": "$(date '+%Y-%m-%d %H:%M:%S')",
    "end_time": "",
    "details": {
        "skipped_repos": [],
        "success_repos": [],
        "failed_repos": []
    }
}
EOF
}

# 更新统计信息
update_stats() {
    local key="$1"
    local value="$2"
    local type="$3"  # 可以是 number 或 array

    if [ "$type" = "array" ]; then
        # 添加到数组
        jq --arg value "$value" \
            ".details.$key += [\$value]" "$STATS_FILE" > "$STATS_FILE.tmp"
    else
        # 更新数值
        jq --arg key "$key" --argjson value "$value" \
            ".$key = \$value" "$STATS_FILE" > "$STATS_FILE.tmp"
    fi
    mv "$STATS_FILE.tmp" "$STATS_FILE"
}

# 同步单个仓库
sync_repository() {
    local repo="$1"
    local success=true
    local repo_path="$CACHE_DIR/$repo"

    echo "开始同步仓库: $repo"
    
    # 检查 Gitea 仓库是否存在
    if ! curl -s -o /dev/null -f -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_USER/$repo"; then
        echo "在 Gitea 上创建仓库 $repo"
        if ! curl -X POST -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "$GITEA_URL/api/v1/user/repos"; then
            echo "创建仓库失败: $repo"
            return 1
        fi
    fi

    # 克隆或更新仓库
    if ! clone_or_update_repo "$repo"; then
        echo "获取仓库失败: $repo"
        return 1
    fi

    # 进入仓库目录进行推送
    cd "$repo_path"

    # 尝试 mirror 推送
    echo "推送仓库 $repo 到 Gitea..."
    if ! git push --mirror "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git"; then
        echo "mirror 推送失败，尝试逐个分支推送..."

        # 获取所有分支
        git fetch --all 2>/dev/null || true

        # 推送每个分支
        for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null); do
            echo "推送分支: $branch"
            if ! git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" "$branch:$branch" 2>/dev/null; then
                echo "分支推送失败: $branch"
                success=false
            fi
        done

        # 推送所有标签
        echo "推送标签..."
        if ! git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" --tags 2>/dev/null; then
            echo "标签推送失败"
            success=false
        fi
    else
        echo "仓库 $repo mirror 推送成功"
    fi
    
    cd - > /dev/null

    if [ "$success" = true ]; then
        echo "仓库 $repo 同步成功"
        update_stats "success" "$(( $(jq '.success' "$STATS_FILE") + 1 ))" "number"
        update_stats "success_repos" "$repo" "array"
        return 0
    else
        echo "仓库 $repo 同步失败"
        update_stats "failed" "$(( $(jq '.failed' "$STATS_FILE") + 1 ))" "number"
        update_stats "failed_repos" "$repo" "array"
        return 1
    fi
}

# 主同步逻辑
main() {
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    # 初始化统计
    init_stats

    # 获取仓库列表
    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=100&type=all" | \
        jq -r '.[].name')

    # 更新总仓库数
    total_repos=$(echo "$repos" | wc -l)
    update_stats "total_repos" "$total_repos" "number"

    # 同步每个仓库
    for repo in $repos; do
        # 检查是否跳过 (使用精确匹配避免部分匹配问题)
        skip_repo=false
        if [ -n "$SKIP_REPOS" ]; then
            # 将逗号分隔的列表转换为数组进行精确匹配
            IFS=',' read -ra SKIP_ARRAY <<< "$SKIP_REPOS"
            for skip_item in "${SKIP_ARRAY[@]}"; do
                # 去除首尾空格并比较
                skip_item=$(echo "$skip_item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ "$repo" = "$skip_item" ]; then
                    skip_repo=true
                    break
                fi
            done
        fi
        
        if [ "$skip_repo" = true ]; then
            echo "跳过仓库: $repo"
            update_stats "skipped" "$(( $(jq '.skipped' "$STATS_FILE") + 1 ))" "number"
            update_stats "skipped_repos" "$repo" "array"
            continue
        fi

        echo "处理仓库: $repo"
        update_stats "processed" "$(( $(jq '.processed' "$STATS_FILE") + 1 ))" "number"
        sync_repository "$repo"
    done

    # 更新结束时间
    jq --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
        '.end_time = $time' "$STATS_FILE" > "$STATS_FILE.tmp"
    mv "$STATS_FILE.tmp" "$STATS_FILE"
}

main "$@"