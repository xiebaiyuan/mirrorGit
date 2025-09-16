#!/bin/bash

# 加载配置
source "$(dirname $0)/.env"

echo "Testing repository count fetching..."

all_repos=""
page=1

while true; do
    echo "Fetching page $page..."
    page_repos=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=100&page=$page&type=all" | \
        jq -r '.[].name // empty')
    
    if [ -z "$page_repos" ]; then
        echo "No more repositories found on page $page. Total pages: $((page - 1))"
        break
    fi
    
    if [ -z "$all_repos" ]; then
        all_repos="$page_repos"
    else
        all_repos="$all_repos
$page_repos"
    fi
    
    repo_count=$(echo "$page_repos" | wc -l)
    echo "Found $repo_count repositories on page $page"
    
    # 如果这一页的仓库数少于100，说明是最后一页
    if [ $repo_count -lt 100 ]; then
        echo "Last page reached (page $page)"
        break
    fi
    
    page=$((page + 1))
done

repos="$all_repos"

if [ -n "$repos" ]; then
    total_repo_count=$(echo "$repos" | wc -l)
    echo "Total repositories found: $total_repo_count"
    
    echo ""
    echo "First 10 repositories:"
    echo "$repos" | head -10
    
    echo ""
    echo "Last 10 repositories:"
    echo "$repos" | tail -10
else
    echo "No repositories found!"
    exit 1
fi