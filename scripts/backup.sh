#!/bin/bash

# ============ 配置区 ============
BACKUP_DIR="$HOME/projects/lnmp-project/mysql/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7
DB_CONTAINER="lnmp_mysql"
DB_NAME="testdb"
DB_USER="root"
DB_PASS="123456778"
# 日志放到项目目录下，避免权限问题
LOG_FILE="$HOME/projects/lnmp-project/logs/backup.log"
# ================================

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# 记录日志（同时输出到终端）
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

backup_full() {
    log "开始全量备份数据库 $DB_NAME..."
    
    # 在容器内执行 mysqldump，通过管道压缩到宿主机
    docker exec "$DB_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB_NAME" 2>/dev/null | gzip > "$BACKUP_DIR/${DB_NAME}_full_${DATE}.sql.gz"
    
    # 检查文件是否真的生成且有内容
    backup_file="$BACKUP_DIR/${DB_NAME}_full_${DATE}.sql.gz"
    if [ -f "$backup_file" ] && [ -s "$backup_file" ]; then
        size=$(du -h "$backup_file" | cut -f1)
        log "备份成功: $(basename "$backup_file") ($size)"
    else
        log "备份失败！请检查容器状态和数据库连接"
        exit 1
    fi
}

cleanup() {
    log "清理 ${RETENTION_DAYS} 天前的备份..."
    
    before_count=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f | wc -l)
    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    after_count=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f | wc -l)
    deleted=$((before_count - after_count))
    
    log "清理完成，删除 $deleted 个旧备份，剩余 $after_count 个"
    
    if [ "$after_count" -gt 0 ]; then
        log "当前备份列表："
        ls -lh "$BACKUP_DIR"/*.sql.gz | tee -a "$LOG_FILE"
    else
        log "当前无备份文件"
    fi
}

# ============ 主程序 ============
log "========== 数据库备份开始 =========="
backup_full
cleanup
log "========== 备份完成 =========="
