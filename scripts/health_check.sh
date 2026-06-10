#!/bin/bash

# 邮件配置
ALERT_EMAIL="3225771583@qq.com"

# 监控的服务列表
SERVICES=("lnmp_nginx:80" "lnmp_php1:9000" "lnmp_mysql:3306")

# 资源告警阈值
ALERT_CPU=80
ALERT_MEM=85
ALERT_DISK=90

# 发送告警邮件
send_alert() {
    local msg="$1"
    local subject="[LNMP告警] $(date '+%H:%M:%S') $msg"
    
    # 使用 sendmail 发送（指定发件人避免 501 错误）
    (
        echo "From: ${ALERT_EMAIL}"
        echo "To: ${ALERT_EMAIL}"
        echo "Subject: ${subject}"
        echo ""
        echo "$msg"
    ) | sendmail "${ALERT_EMAIL}"
    
    # 同时输出到终端（红色高亮）
    echo -e "\033[31m[$(date '+%H:%M:%S')] 告警: $msg\033[0m"
}

# 检查容器状态
check_containers() {
    for service in "${SERVICES[@]}"; do
        name=$(echo "$service" | cut -d: -f1)
        port=$(echo "$service" | cut -d: -f2)
        
        # 检查容器是否运行
        if ! docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
            msg="容器 $name 未运行！"
            send_alert "$msg"
            continue
        fi
        
        # 检查端口是否响应
        if ! docker exec "$name" sh -c "nc -z localhost $port" 2>/dev/null; then
            msg="服务 $name 端口 $port 无响应！"
            send_alert "$msg"
        fi
    done
}

# 检查系统资源
check_resources() {
    # CPU 检测
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
    if [ -n "$cpu_usage" ] && (( $(echo "$cpu_usage > $ALERT_CPU" | bc -l 2>/dev/null || echo 0) )); then
        msg="CPU 使用率 ${cpu_usage}%，超过阈值 ${ALERT_CPU}%"
        send_alert "$msg"
    fi
    
    # 内存检测
    mem_usage=$(free | awk '/Mem/{printf("%.0f"), $3/$2*100}')
    if [ "$mem_usage" -gt "$ALERT_MEM" ]; then
        msg="内存使用率 ${mem_usage}%，超过阈值 ${ALERT_MEM}%"
        send_alert "$msg"
    fi
    
    # 磁盘检测
    disk_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$disk_usage" -gt "$ALERT_DISK" ]; then
        msg="磁盘使用率 ${disk_usage}%，超过阈值 ${ALERT_DISK}%"
        send_alert "$msg"
    fi
}

# 主程序
echo "========== $(date '+%Y-%m-%d %H:%M:%S') LNMP 健康检查 =========="

check_containers
check_resources

echo "检查完成"
