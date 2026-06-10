#!/bin/bash

LOG_DIR="$HOME/projects/lnmp-project/logs/nginx"
DATE=$(date +%Y%m%d)
MAX_SIZE=104857600

rotate() {
    for logfile in access.log error.log; do
        filepath="$LOG_DIR/$logfile"

        if [ ! -f "$filepath" ]; then
            continue
        fi

        mv "$filepath" "$LOG_DIR/${logfile}.${DATE}"
        docker kill --signal=USR1 lnmp_nginx 2>/dev/null || true

        find "$LOG_DIR" -name "*.log.*" -mtime +1 -exec gzip {} \;
        find "$LOG_DIR" -name "*.gz" -mtime +30 -delete

        echo "[$(date)] 日志切割完成: $logfile"
    done
}

check_size() {
    for logfile in access.log error.log; do
        filepath="$LOG_DIR/$logfile"
        if [ -f "$filepath" ]; then
            size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath")
            if [ "$size" -gt "$MAX_SIZE" ]; then
                echo "[$(date)] $logfile 超过 ${MAX_SIZE} bytes，触发切割"
                rotate
            fi
        fi
    done
}

rotate
check_size
