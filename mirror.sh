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
        jq --arg key "$key" --arg value "$value" \
            ".details[$key] += [\$value]" "$STATS_FILE" > "$STATS_FILE.tmp"
    else
        # 更新数值
        jq --arg key "$key" --arg value "$value" \
            ".[$key] = ($value | tonumber)" "$STATS_FILE" > "$STATS_FILE.tmp"
    fi
    mv "$STATS_FILE.tmp" "$STATS_FILE"
}

# 同步单个仓库
sync_repository() {
    local repo="$1"
    local success=true

    # 检查 Gitea 仓库是否存在
    if ! curl -s -o /dev/null -f -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_USER/$repo"; then
        echo "在 Gitea 上创建仓库 $repo"
        if ! curl -X POST -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "$GITEA_URL/api/v1/user/repos"; then
            success=false
        fi
    fi

    # 克隆和推送
    [ -d "$repo" ] && rm -rf "$repo"
    if ! git clone --mirror "https://${GITHUB_TOKEN:+$GITHUB_TOKEN@}github.com/$GITHUB_USER/$repo.git" "$repo"; then
        success=false
    else
        cd "$repo"

        # 尝试 mirror 推送
        if ! git push --mirror "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git"; then
            echo "mirror 推送失败，尝试逐个分支推送..."

            # 获取所有分支
            git fetch --all

            # 推送每个分支
            git for-each-ref --format='%(refname:short)' refs/heads/ | while read branch; do
                echo "推送分支: $branch"
                if ! git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" "$branch:$branch"; then
                    success=false
                fi
            done

            # 推送所有标签
            if ! git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" --tags; then
                success=false
            fi
        fi
        cd ..
    fi

    # 更新统计
    if [ "$success" = true ]; then
        update_stats "success" "$(( $(jq '.success' "$STATS_FILE") + 1 ))" "number"
        update_stats "success_repos" "$repo" "array"
    else
        update_stats "failed" "$(( $(jq '.failed' "$STATS_FILE") + 1 ))" "number"
        update_stats "failed_repos" "$repo" "array"
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
        # 检查是否跳过
        if echo "$SKIP_REPOS" | grep -q "$repo"; then
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