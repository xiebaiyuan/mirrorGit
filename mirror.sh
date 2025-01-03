#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置信息
GITHUB_USER="your-github-username"
GITHUB_TOKEN="your-github-token"  # 如果需要访问私有仓库
GITEA_URL="https://your-gitea-instance"
GITEA_USER="your-gitea-username"
GITEA_TOKEN="your-gitea-token"

# 工作目录
WORK_DIR="/tmp/git-mirror"

# 错误处理函数
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 检查必要的命令是否存在
command -v git >/dev/null 2>&1 || error_exit "需要安装 git"
command -v curl >/dev/null 2>&1 || error_exit "需要安装 curl"
command -v jq >/dev/null 2>&1 || error_exit "需要安装 jq"

# 创建工作目录
mkdir -p "$WORK_DIR" || error_exit "无法创建工作目录"
cd "$WORK_DIR" || error_exit "无法进入工作目录"

# 获取所有 GitHub 仓库列表
echo -e "${YELLOW}正在获取 GitHub 仓库列表...${NC}"
if [ -n "$GITHUB_TOKEN" ]; then
    repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/users/$GITHUB_USER/repos?per_page=100" | \
        jq -r '.[].name')
else
    repos=$(curl -s "https://api.github.com/users/$GITHUB_USER/repos?per_page=100" | \
        jq -r '.[].name')
fi

[ -z "$repos" ] && error_exit "无法获取仓库列表"

# 计数器
total=$(echo "$repos" | wc -l)
current=0

for repo in $repos; do
    ((current++))
    echo -e "\n${YELLOW}处理仓库 ($current/$total): $repo${NC}"

    # 检查 Gitea 仓库是否存在
    if curl -s -I -H "Authorization: token $GITEA_TOKEN" \
        "$GITEA_URL/api/v1/repos/$GITEA_USER/$repo" | \
        grep -q "404 Not Found"; then

        echo "在 Gitea 上创建仓库 $repo"
        curl -X POST -H "Authorization: token $GITEA_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "$GITEA_URL/api/v1/user/repos" || \
            error_exit "无法在 Gitea 上创建仓库 $repo"
    fi

    # 如果目录已存在，先删除
    [ -d "$repo" ] && rm -rf "$repo"

    # 克隆 GitHub 仓库
    echo "克隆 GitHub 仓库..."
    if [ -n "$GITHUB_TOKEN" ]; then
        git clone --mirror "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$repo.git" "$repo" || \
            error_exit "无法克隆仓库 $repo"
    else
        git clone --mirror "https://github.com/$GITHUB_USER/$repo.git" "$repo" || \
            error_exit "无法克隆仓库 $repo"
    fi

    cd "$repo" || error_exit "无法进入仓库目录 $repo"

    # 推送到 Gitea
    echo "推送到 Gitea..."
    git push --mirror "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" || \
        error_exit "无法推送到 Gitea 仓库 $repo"

    cd "$WORK_DIR" || error_exit "无法返回工作目录"
    rm -rf "$repo"

    echo -e "${GREEN}成功同步仓库: $repo${NC}"
done

echo -e "\n${GREEN}所有仓库同步完成!${NC}"

# 清理工作目录
cd / && rm -rf "$WORK_DIR"