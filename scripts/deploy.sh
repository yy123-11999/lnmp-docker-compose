#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/lnmp-deploy.log"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 兼容新版 docker compose 命令
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    echo "ERROR: Docker Compose 未安装"
    exit 1
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

check_deps() {
    log "检查依赖环境..."
    command -v docker >/dev/null 2>&1 || error_exit "Docker 未安装"
    
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker 服务未运行"
    fi
    
    log "依赖检查通过 ✓"
}

init_dirs() {
    log "初始化目录结构..."
    mkdir -p "$PROJECT_DIR"/logs/{nginx,php,mysql}
    mkdir -p "$PROJECT_DIR"/mysql/backup
    chmod 755 "$PROJECT_DIR"/logs/*
    log "目录初始化完成 ✓"
}

deploy() {
    log "开始部署 LNMP 环境..."
    cd "$PROJECT_DIR"

    $DOCKER_COMPOSE pull
    $DOCKER_COMPOSE build --no-cache
    $DOCKER_COMPOSE up -d

    log "等待 MySQL 启动..."
    for i in {1..30}; do
        if $DOCKER_COMPOSE exec -T mysql mysqladmin ping --silent 2>/dev/null; then
            log "MySQL 就绪 ✓"
            break
        fi
        sleep 2
    done

    log "部署完成！服务状态："
    $DOCKER_COMPOSE ps
}

stop() {
    log "停止所有服务..."
    cd "$PROJECT_DIR"
    $DOCKER_COMPOSE down
    log "服务已停止 ✓"
}

restart() {
    log "重启服务..."
    stop
    deploy
}

status() {
    cd "$PROJECT_DIR"
    echo -e "${YELLOW}=== 容器状态 ===${NC}"
    $DOCKER_COMPOSE ps
    echo -e "\n${YELLOW}=== 资源使用 ===${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" || true
}

case "${1:-deploy}" in
    deploy)  check_deps; init_dirs; deploy ;;
    stop)    stop ;;
    restart) restart ;;
    status)  status ;;
    *)       echo "用法: $0 {deploy|stop|restart|status}"; exit 1 ;;
esac
