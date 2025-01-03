#!/bin/bash

# 参数获取
SMTP_SERVER="$1"
SMTP_PORT="$2"
SMTP_USER="$3"
SMTP_PASS="$4"
MAIL_TO="$5"
MAIL_FROM="$6"
SUBJECT="$7"
BODY="$8"

# 发送邮件
send_mail() {
    local email_content="Subject: $SUBJECT
From: $MAIL_FROM
To: $MAIL_TO
Content-Type: text/plain; charset=UTF-8
Date: $(date -R)

$BODY"

    curl -s --url "smtps://$SMTP_SERVER:$SMTP_PORT" \
        --mail-from "$MAIL_FROM" \
        --mail-rcpt "$MAIL_TO" \
        --upload-file - \
        --ssl-reqd \
        --user "$SMTP_USER:$SMTP_PASS" \
        <<< "$email_content"
}

# 主函数
main() {
    # 验证必要参数
    if [ -z "$SMTP_SERVER" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ] || [ -z "$MAIL_TO" ]; then
        echo "错误: 缺少必要的邮件配置"
        exit 1
    fi

    send_mail
}

main "$@"