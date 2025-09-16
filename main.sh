#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR=$(readlink -f $(dirname $0))

# 加载配置
source "$SCRIPT_DIR/config.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 初始化日志
init_logging() {
    mkdir -p "$LOG_DIR"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
}

# 日志函数
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "$timestamp $message"
}

# 检查必要的命令
check_requirements() {
    command -v git >/dev/null 2>&1 || error_exit "需要安装 git"
    command -v curl >/dev/null 2>&1 || error_exit "需要安装 curl"
    command -v jq >/dev/null 2>&1 || error_exit "需要安装 jq"
}

# 断点恢复和临时文件
CHECKPOINT_FILE="$WORK_DIR/checkpoint.json"
REPO_LIST_FILE="$WORK_DIR/repos_list.json"

# 创建断点
create_checkpoint() {
    local repo="$1"
    local status="$2"
    local progress_file="$CHECKPOINT_FILE"
    
    # 确保目录存在
    mkdir -p "$(dirname "$progress_file")"
    
    # 创建或更新断点文件
    if [ ! -f "$progress_file" ]; then
        echo '{"last_processed": "", "status": "in_progress", "timestamp": ""}' > "$progress_file"
    fi
    
    # 更新断点信息
    jq --arg repo "$repo" --arg status "$status" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
       '.last_processed = $repo | .status = $status | .timestamp = $time' \
       "$progress_file" > "${progress_file}.tmp"
    mv "${progress_file}.tmp" "$progress_file"
    
    log "${BLUE}更新断点: 最后处理的仓库 - $repo${NC}"
}

# 检查断点
check_checkpoint() {
    local progress_file="$CHECKPOINT_FILE"
    
    if [ -f "$progress_file" ]; then
        local last_repo=$(jq -r '.last_processed' "$progress_file")
        local status=$(jq -r '.status' "$progress_file")
        local time=$(jq -r '.timestamp' "$progress_file")
        
        if [ "$status" = "in_progress" ] && [ -n "$last_repo" ]; then
            log "${YELLOW}检测到之前的同步被中断，从 $last_repo 继续${NC}"
            log "上次同步时间: $time"
            echo "$last_repo"
            return 0
        fi
    fi
    
    echo ""
    return 1
}

# 主函数
main() {
    init_logging
    check_requirements

    log "${CYAN}======== GitHub 镜像同步任务开始 ========${NC}"
    log "配置信息:"
    log "- GitHub 用户: ${GITHUB_USER}"
    log "- Gitea URL: ${GITEA_URL}"
    log "- 工作目录: ${WORK_DIR}"
    log ""

    # 提前获取并展示仓库列表
    log "${YELLOW}正在获取仓库列表...${NC}"
    mkdir -p "$WORK_DIR"
    
    # 检查之前的仓库列表是否存在
    local use_existing_list=false
    if [ -f "$REPO_LIST_FILE" ]; then
        log "${YELLOW}发现现有仓库列表，检查是否可用...${NC}"
        local file_age=$(($(date +%s) - $(date -r "$REPO_LIST_FILE" +%s)))
        # 如果文件不超过24小时，则使用现有列表
        if [ $file_age -lt 86400 ]; then
            use_existing_list=true
            log "${GREEN}使用现有仓库列表（创建于$(date -r "$REPO_LIST_FILE")）${NC}"
        else
            log "${YELLOW}仓库列表过旧，重新获取${NC}"
        fi
    fi
    
    local all_repos=()
    
    if [ "$use_existing_list" = true ]; then
        # 从现有文件读取仓库列表
        readarray -t all_repos < <(jq -r '.[]' "$REPO_LIST_FILE")
    else
        # 重新从GitHub获取仓库列表
        local page=1
        local temp_repos=()
        
        while true; do
            log "获取第 $page 页仓库..."
            local response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/user/repos?per_page=100&page=$page&type=all")
            
            local page_repos=($(echo "$response" | jq -r '.[].name'))
            
            if [ ${#page_repos[@]} -eq 0 ]; then
                break
            fi
            
            temp_repos+=("${page_repos[@]}")
            log "第 $page 页找到 ${#page_repos[@]} 个仓库"
            
            page=$((page+1))
        done
        
        all_repos=("${temp_repos[@]}")
        
        # 保存仓库列表到文件中以便下次使用
        printf '%s\n' "${all_repos[@]}" | jq -R . | jq -s . > "$REPO_LIST_FILE"
        log "${GREEN}仓库列表已保存到 $REPO_LIST_FILE${NC}"
    fi
    
    log "${GREEN}找到 ${#all_repos[@]} 个仓库需要同步${NC}"
    log ""
    log "${CYAN}即将同步的仓库:${NC}"
    
    # 检查上次的断点
    local resume_from=""
    local should_resume=false
    resume_from=$(check_checkpoint)
    if [ -n "$resume_from" ]; then
        should_resume=true
        log "${YELLOW}将从上次中断的位置继续: $resume_from${NC}"
    fi
    
    # 展示即将同步的仓库地址
    local resume_reached=false
    if [ "$should_resume" = false ]; then
        resume_reached=true
    fi
    for repo in "${all_repos[@]}"; do
        # 判断是否需要跳过（基于SKIP_REPOS配置）
        local skip_this_repo=false
        if [[ "$SKIP_REPOS" =~ (^|,)"$repo"(,|$) ]]; then
            skip_this_repo=true
        fi
        
        # 检查是否已经达到断点恢复位置
        if [ "$should_resume" = true ] && [ "$resume_reached" = false ]; then
            if [ "$repo" = "$resume_from" ]; then
                resume_reached=true
            else
                continue  # 跳过之前已处理的仓库
            fi
        fi
        
        # 显示仓库信息
        if [ "$skip_this_repo" = true ]; then
            log "- ${RED}https://github.com/$GITHUB_USER/$repo${NC} (将跳过)"
        else
            if [ "$resume_reached" = true ]; then
                log "- ${YELLOW}https://github.com/$GITHUB_USER/$repo${NC}"
            else
                log "- ${BLUE}https://github.com/$GITHUB_USER/$repo${NC} (已处理)"
            fi
        fi
    done
    
    log ""
    log "${CYAN}======== 开始同步处理 ========${NC}"
    
    # 创建临时目录来保存仓库特定的统计信息
    local repo_stats_dir="$WORK_DIR/repo_stats"
    mkdir -p "$repo_stats_dir"
    
    # 如果不是继续同步，则初始化统计文件
    if [ "$should_resume" = false ] && [ -f "$STATS_FILE" ]; then
        rm "$STATS_FILE"
    fi
    
    # 同步仓库
    local success_repos=()
    local failed_repos=()
    local skipped_repos=()
    local total_processed=0

    # 调用 mirror.sh 进行同步
    for repo in "${all_repos[@]}"; do
        # 判断是否需要跳过（基于SKIP_REPOS配置）
        local skip_this_repo=false
        if [[ "$SKIP_REPOS" =~ (^|,)"$repo"(,|$) ]]; then
            skip_this_repo=true
            skipped_repos+=("$repo")
            continue
        fi
        
        # 检查是否已经达到断点恢复位置
        if [ "$should_resume" = true ] && [ "$resume_reached" = false ]; then
            if [ "$repo" = "$resume_from" ]; then
                resume_reached=true
            else
                continue  # 跳过之前已处理的仓库
            fi
        fi
        
        # 跳过没有达到恢复点的仓库
        if [ "$resume_reached" = false ]; then
            continue
        fi
        
        # 显示当前正在处理的仓库
        log "${CYAN}正在同步 ($((total_processed+1))/${#all_repos[@]}): ${YELLOW}$repo${NC}"
        
        # 创建断点
        create_checkpoint "$repo" "in_progress"
        
        # 调用 mirror.sh 进行单个仓库的同步
        bash "$SCRIPT_DIR/mirror.sh" \
            "$GITHUB_USER" \
            "$GITHUB_TOKEN" \
            "$GITEA_URL" \
            "$GITEA_USER" \
            "$GITEA_TOKEN" \
            "$WORK_DIR" \
            "$repo" \
            "$repo_stats_dir/$repo.json" \
            "single"  # 添加一个参数表示单个仓库模式
        
        mirror_exit_code=$?
        total_processed=$((total_processed+1))
        
        # 检查同步结果
        if [ $mirror_exit_code -eq 0 ]; then
            success_repos+=("$repo")
            log "${GREEN}仓库 $repo 同步成功${NC}"
            # 更新断点状态为成功
            create_checkpoint "$repo" "success"
        else
            failed_repos+=("$repo")
            log "${RED}仓库 $repo 同步失败${NC}"
            # 更新断点状态为失败
            create_checkpoint "$repo" "failed"
        fi
        
        # 显示仓库大小
        local repo_dir="$WORK_DIR/repos/$repo"
        if [ -d "$repo_dir" ]; then
            local size=$(du -sh "$repo_dir" | cut -f1)
            log "- ${GREEN}$repo${NC}: ${YELLOW}$size${NC}"
        fi
        
        log "已完成: ${#success_repos[@]} 成功, ${#failed_repos[@]} 失败, ${#skipped_repos[@]} 跳过, 总进度: $total_processed/${#all_repos[@]}"
        log "------------------------"
    done

    # 生成总体统计信息
    log ""
    log "${CYAN}======== 同步处理结束 ========${NC}"
    
    # 准备统计信息
    cat > "$STATS_FILE" << EOF
{
    "total_repos": ${#all_repos[@]},
    "processed": $total_processed,
    "skipped": ${#skipped_repos[@]},
    "success": ${#success_repos[@]},
    "failed": ${#failed_repos[@]},
    "start_time": "$(date '+%Y-%m-%d %H:%M:%S')",
    "end_time": "$(date '+%Y-%m-%d %H:%M:%S')",
    "details": {
        "skipped_repos": $(printf '%s\n' "${skipped_repos[@]}" | jq -R . | jq -s .),
        "success_repos": $(printf '%s\n' "${success_repos[@]}" | jq -R . | jq -s .),
        "failed_repos": $(printf '%s\n' "${failed_repos[@]}" | jq -R . | jq -s .)
    }
}
EOF
    
    # 显示同步完成的仓库及其大小
    if [ ${#success_repos[@]} -gt 0 ]; then
        log "${GREEN}成功同步的仓库及其大小:${NC}"
        
        for repo in "${success_repos[@]}"; do
            local repo_dir="$WORK_DIR/repos/$repo"
            if [ -d "$repo_dir" ]; then
                local size=$(du -sh "$repo_dir" | cut -f1)
                log "- ${GREEN}$repo${NC}: ${YELLOW}$size${NC}"
            else
                log "- ${GREEN}$repo${NC}: 大小未知"
            fi
        done
    fi

    # 设置断点为完成
    if [ -f "$CHECKPOINT_FILE" ]; then
        jq '.status = "completed" | .timestamp = "'"$(date '+%Y-%m-%d %H:%M:%S')"'"' \
           "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
        mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
    fi

    # 准备邮件内容
    notice_subject="GitHub 同步$([ ${#failed_repos[@]} -eq 0 ] && echo "成功" || echo "部分失败") - $(date '+%Y-%m-%d')"
    summary=""

    if [ -f "$STATS_FILE" ]; then
        stats=$(cat "$STATS_FILE")
        summary="GitHub to Gitea 同步报告

开始时间: $(echo "$stats" | jq -r '.start_time')
结束时间: $(echo "$stats" | jq -r '.end_time')
同步状态: $([ ${#failed_repos[@]} -eq 0 ] && echo "成功" || echo "部分失败 (${#failed_repos[@]} 个仓库)")

统计信息:
- 总仓库数: $(echo "$stats" | jq -r '.total_repos')
- 处理数量: $(echo "$stats" | jq -r '.processed')
- 成功数量: $(echo "$stats" | jq -r '.success')
- 失败数量: $(echo "$stats" | jq -r '.failed')
- 跳过数量: $(echo "$stats" | jq -r '.skipped')

跳过的仓库:
$(echo "$stats" | jq -r '.details.skipped_repos[] // empty' | sed 's/^/- /')

失败的仓库:
$(echo "$stats" | jq -r '.details.failed_repos[] // empty' | sed 's/^/- /')

成功的仓库：
$(echo "$stats" | jq -r '.details.success_repos[] // empty' | sed 's/^/- /')
"

    else
        summary="无法获取同步统计信息"
    fi

    notice_content="$summary

详细日志 (最后 50 行):
$(tail -n 50 "$LOG_FILE")

全部日志:
$(cat "$LOG_FILE")
"

    # 如果启用了邮件通知，调用 mail.sh
    if [ "$ENABLE_MAIL" = "true" ]; then
        log "${CYAN}正在发送邮件通知...${NC}"
        bash "$SCRIPT_DIR/mail.sh" \
            "$SMTP_SERVER" \
            "$SMTP_PORT" \
            "$SMTP_USER" \
            "$SMTP_PASS" \
            "$MAIL_TO" \
            "$MAIL_FROM" \
            "$notice_subject" \
            "$notice_content"
    fi

    # 如果启用了飞书通知，调用 feishu_notify.sh
    if [ "$ENABLE_FEISHU" = "true" ]; then
        log "${CYAN}正在发送飞书通知...${NC}"
        bash "$SCRIPT_DIR/feishu_notify.sh" \
            "$FEISHU_WEBHOOK_URL" \
            "$notice_subject" \
            "$notice_content"
    fi


    # 清理工作目录
    if [ ${#failed_repos[@]} -eq 0 ]; then
        log "${YELLOW}同步完全成功，清理工作目录...${NC}"
        [ -d "$WORK_DIR" ] && rm -rf "$WORK_DIR"
    else
        log "${YELLOW}同步有失败项，保留工作目录以便恢复: $WORK_DIR${NC}"
        log "可通过再次运行脚本继续同步未完成的仓库"
    fi

    # 最终同步状态
    local final_status=0
    if [ ${#failed_repos[@]} -gt 0 ]; then
        final_status=1
        log "${RED}======== 任务部分失败 (${#failed_repos[@]} 个仓库失败) ========${NC}"
    else
        log "${GREEN}======== 任务全部成功完成 ========${NC}"
    fi
    
    exit $final_status
}

main "$@"
