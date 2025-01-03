#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置信息
GITHUB_USER=${GITHUB_USER:-"default-github-username"}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}  # 可选的 GitHub Token
GITEA_URL=${GITEA_URL:-"https://your-gitea-instance"}
GITEA_USER=${GITEA_USER:-"default-gitea-username"}
GITEA_TOKEN=${GITEA_TOKEN:-"default-gitea-token"}

cur_path=$(readlink -f $(dirname $0))
# 工作目录
WORK_DIR=${cur_path}/"./tmp"

# 跳过的仓库列表（逗号分隔）
SKIP_REPOS=${SKIP_REPOS:-"archive,AutoApiSecret, \
                  backup-openbilibili-go-common, \
                  carrot,ChatGLM-6B,dokploy,hub-mirror, \
                  Download-macOS, \
                  songtianlun,songtianlun.github.io"}


# 将跳过的仓库字符串转换为数组
IFS=',' read -ra SKIP_REPOS_ARRAY <<< "$SKIP_REPOS"
declare -A SKIP_REPOS_MAP  # 声明关联数组

# 将跳过的仓库添加到映射中，以便快速查找
for repo in "${SKIP_REPOS_ARRAY[@]}"; do
    # 去除可能存在的空格
    repo=$(echo "$repo" | tr -d ' ')
    if [ -n "$repo" ]; then
        SKIP_REPOS_MAP[$repo]=1
    fi
done

# 检查仓库是否在跳过列表中
is_repo_skipped() {
    local repo_name="$1"
    [[ -n "${SKIP_REPOS_MAP[$repo_name]}" ]]
}

# 显示配置信息
show_config() {
    echo -e "${BLUE}当前配置信息:${NC}"
    echo -e "GitHub 用户: ${YELLOW}$GITHUB_USER${NC}"
    echo -e "GitHub Token: ${YELLOW}${GITHUB_TOKEN:+已设置}${NC}"
    echo -e "Gitea URL: ${YELLOW}$GITEA_URL${NC}"
    echo -e "Gitea 用户: ${YELLOW}$GITEA_USER${NC}"
    echo -e "工作目录: ${YELLOW}$WORK_DIR${NC}"
    if [ ${#SKIP_REPOS_ARRAY[@]} -gt 0 ]; then
        echo -e "跳过的仓库: ${YELLOW}${SKIP_REPOS}${NC}"
    fi
    echo
}

# 检查必要的配置
check_required_vars() {
    local missing_vars=()

    [ "$GITHUB_USER" = "default-github-username" ] && missing_vars+=("GITHUB_USER")
    [ "$GITEA_URL" = "https://your-gitea-instance" ] && missing_vars+=("GITEA_URL")
    [ "$GITEA_USER" = "default-gitea-username" ] && missing_vars+=("GITEA_USER")
    [ "$GITEA_TOKEN" = "default-gitea-token" ] && missing_vars+=("GITEA_TOKEN")

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "${RED}错误: 以下必需的环境变量未设置:${NC}"
        printf '%s\n' "${missing_vars[@]}"
        echo -e "\n${YELLOW}请设置环境变量后再运行，例如：${NC}"
        echo "export GITHUB_USER=your-username"
        echo "export GITEA_URL=https://your-gitea-instance"
        echo "export GITEA_USER=your-gitea-username"
        echo "export GITEA_TOKEN=your-gitea-token"
        echo "export SKIP_REPOS=repo1,repo2,repo3"  # 可选
        exit 1
    fi
}

# 错误处理函数
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 检查配置
check_required_vars
show_config

# 检查必要的命令是否存在
command -v git >/dev/null 2>&1 || error_exit "需要安装 git"
command -v curl >/dev/null 2>&1 || error_exit "需要安装 curl"
command -v jq >/dev/null 2>&1 || error_exit "需要安装 jq"

# 创建工作目录
mkdir -p "$WORK_DIR" || error_exit "无法创建工作目录"
cd "$WORK_DIR" || error_exit "无法进入工作目录"

# 获取所有 GitHub 仓库列表
echo -e "${YELLOW}正在获取 GitHub 仓库列表...${NC}"
# 检查 API 限制
#if [ -n "$GITHUB_TOKEN" ]; then
#    rate_limit=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
#        "https://api.github.com/rate_limit")
#    echo "API 限制信息："
#    echo "$rate_limit" | jq .
#fi
all_repos=""
page=1
# 在获取仓库列表的循环中添加调试信息
while true; do
    #echo "获取第 $page 页的仓库..."
    if [ -n "$GITHUB_TOKEN" ]; then
        page_repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/user/repos?per_page=100&page=$page&type=all" | \
            tee /tmp/github-response-$page.json | \
            jq -r '.[].name')
    else
        page_repos=$(curl -s \
            "https://api.github.com/user/repos?per_page=100&page=$page&type=all" | \
            tee /tmp/github-response-$page.json | \
            jq -r '.[].name')
    fi

    # 显示获取到的仓库数量
    #count=$(echo "$page_repos" | grep -v '^$' | wc -l)
    #echo "第 $page 页获取到 $count 个仓库"

    if [ -z "$page_repos" ] || [ "$page_repos" = "null" ]; then
    #    echo "没有更多仓库，退出循环"
        break
    fi

    all_repos="${all_repos}${page_repos}\n"
    ((page++))
done

# 移除多余的空行并存储到 repos 变量
repos=$(echo -e "$all_repos" | grep -v '^$')

[ -z "$repos" ] && error_exit "无法获取仓库列表"

# 显示获取到的总仓库数
total_repos=$(echo "$repos" | wc -l)
echo -e "${GREEN}总共获取到 $total_repos 个仓库${NC}"

# 计数器
total=$(echo "$repos" | wc -l)
current=0
skipped=0
processed=0

for repo in $repos; do
    ((current++))

    # 检查是否跳过该仓库
    if is_repo_skipped "$repo"; then
        echo -e "\n${BLUE}跳过仓库 ($current/$total): $repo${NC}"
        ((skipped++))
        continue
    fi

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
        git clone -q --mirror "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$repo.git" "$repo" || \
            error_exit "无法克隆仓库 $repo"
    else
        git clone -q --mirror "https://github.com/$GITHUB_USER/$repo.git" "$repo" || \
            error_exit "无法克隆仓库 $repo"
    fi

    cd "$repo" || error_exit "无法进入仓库目录 $repo"

    # 确保获取所有分支和标签
    git fetch --all --tags

    # 推送到 Gitea
    echo "推送到 Gitea..."
    # 尝试 mirror 推送
    if git push -q --mirror "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git"; then
        echo "mirror 推送成功"
    else
        echo "mirror 推送失败，尝试逐个分支推送..."

        # 获取所有远程分支，去除 'origin/' 前缀
        branches=$(git branch -r | grep -v '\->' | sed 's/origin\///')
        push_failed=false

        # 逐个推送分支
        for branch in $branches; do
            echo "推送分支: $branch"
            if ! git push -q "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" "origin/$branch:$branch"; then
                echo "警告: 推送分支 $branch 失败"
                push_failed=true
            fi
        done

        # 推送所有标签
        tags=$(git tag)
        if [ -n "$tags" ]; then
            echo "推送标签..."
            for tag in $tags; do
                if ! git push -q "https://$GITEA_USER:$GITEA_TOKEN@${GITEA_URL#https://}/$GITEA_USER/$repo.git" "refs/tags/$tag"; then
                    echo "警告: 推送标签 $tag 失败"
                    push_failed=true
                fi
            done
        fi

        # 如果有任何分支或标签推送失败，抛出错误
        if [ "$push_failed" = true ]; then
            error_exit "部分分支或标签推送失败，请检查日志"
        fi
    fi


    cd "$WORK_DIR" || error_exit "无法返回工作目录"
    rm -rf "$repo"

    echo -e "${GREEN}成功同步仓库: $repo${NC}"
    ((processed++))
done

echo -e "\n${GREEN}同步完成!${NC}"
echo -e "处理总数: $current"
echo -e "成功同步: $processed"
echo -e "跳过数量: $skipped"

# 清理工作目录
cd / && rm -rf "$WORK_DIR"