#!/bin/bash

# 测试修复后的仓库名称处理

echo "=== 测试仓库名称清理 ==="

# 模拟可能有问题的仓库名称
test_repos="test-repo
another-repo 
repo-with-carriage-return\r
normal-repo"

echo "原始数据:"
echo "$test_repos" | xxd

echo ""
echo "处理后的仓库:"

echo "$test_repos" | while IFS= read -r repo; do
    if [ -n "$repo" ]; then
        # 应用与脚本中相同的清理逻辑
        cleaned_repo=$(echo "$repo" | tr -d '\r\n' | sed 's/[[:space:]]*$//')
        
        # 跳过空行
        [ -z "$cleaned_repo" ] && continue
        
        printf "Original: [%s] -> Cleaned: [%s]\n" "$repo" "$cleaned_repo"
    fi
done

echo ""
echo "=== 测试完成 ==="