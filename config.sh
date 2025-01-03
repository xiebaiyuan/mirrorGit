#!/bin/bash

# GitHub 配置
GITHUB_USER=${GITHUB_USER:-"default-github-username"}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}

# Gitea 配置
GITEA_URL=${GITEA_URL:-"https://your-gitea-instance"}
GITEA_USER=${GITEA_USER:-"default-gitea-username"}
GITEA_TOKEN=${GITEA_TOKEN:-"default-gitea-token"}

# 工作目录配置
WORK_DIR=${WORK_DIR:-"/tmp/github-mirror"}
LOG_DIR=${LOG_DIR:-"$WORK_DIR/logs"}

# 邮件配置
ENABLE_MAIL=${ENABLE_MAIL:-"false"}
SMTP_SERVER=${SMTP_SERVER:-""}
SMTP_PORT=${SMTP_PORT:-"587"}
SMTP_USER=${SMTP_USER:-""}
SMTP_PASS=${SMTP_PASS:-""}
MAIL_TO=${MAIL_TO:-""}
MAIL_FROM=${MAIL_FROM:-"$SMTP_USER"}

# 跳过的仓库
SKIP_REPOS=${SKIP_REPOS:-"archive,AutoApiSecret, \
                  backup-openbilibili-go-common, \
                  carrot,ChatGLM-6B,dokploy,hub-mirror, \
                  Download-macOS, \
                  songtianlun,songtianlun.github.io"}