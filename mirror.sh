#!/bin/bash

# 参数获取
GITHUB_USER="$1"
GITHUB_TOKEN="$2"
GITEA_URL="$3"
GITEA_USER="$4"
GITEA_TOKEN="$5"
WORK_DIR="$6"
SKIP_REPOS="$7"

# 同步单个仓库
sync_repository() {
    local repo="$1"

    # 检查 Gitea 仓库是否存在
    if ! curl -s -o /dev/null -f -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_USER/$repo"; then

        echo "在 Gitea 上创建仓库 $repo"
        curl -X POST -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "$GITEA_URL/api/v1/user/repos"
    fi

    # 克隆和推送
    [ -d "$repo" ] && rm -rf "$repo"
    git clone --mirror "https://${GITHUB_TOKEN:+$GITHUB_TOKEN@}github.com/$GITHUB_USER/$repo.git" "$repo"
    cd "$repo"

    # 尝试 mirror 推送
    if ! git push --mirror "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git"; then
        echo "mirror 推送失败，尝试逐个分支推送..."

        # 获取所有分支
        git fetch --all

        # 推送每个分支
        git for-each-ref --format='%(refname:short)' refs/heads/ | while read branch; do
            echo "推送分支: $branch"
            git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" "$branch:$branch"
        done

        # 推送所有标签
        git push "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" --tags
    fi

    cd ..
}

# 主同步逻辑
main() {
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"

    # 获取仓库列表
    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=100&type=all" | \
        jq -r '.[].name')

    # 同步每个仓库
    for repo in $repos; do
        # 检查是否跳过
        if echo "$SKIP_REPOS" | grep -q "$repo"; then
            echo "跳过仓库: $repo"
            continue
        fi

        echo "处理仓库: $repo"
        sync_repository "$repo"
    done
}

main "$@"