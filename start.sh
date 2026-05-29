#!/bin/bash

# ============================================
# IoT 项目快速启动脚本 (macOS)
# ============================================
# 用法: ./start.sh [option]
# 选项:
#   start     - 启动所有服务
#   stop      - 停止所有服务
#   restart   - 重启所有服务
#   status    - 查看服务状态
#   setup     - 初始化环境（仅首次运行）
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TCP_SERVER="$SCRIPT_DIR/BackgroundServer/TCP/main"
MQTT_SERVER="$SCRIPT_DIR/BackgroundServer/MQTT/main"
TCP_PID_FILE="/tmp/iot_tcp.pid"
MQTT_PID_FILE="/tmp/iot_mqtt.pid"

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    local missing_deps=()
    
    # 检查 MySQL
    if ! command -v mysql &> /dev/null; then
        missing_deps+=("mysql")
    fi
    
    # 检查 g++
    if ! command -v g++ &> /dev/null; then
        missing_deps+=("gcc")
    fi
    
    # 检查 Boost
    if [ ! -f "/opt/homebrew/include/boost/asio.hpp" ] && [ ! -f "/usr/local/include/boost/asio.hpp" ]; then
        missing_deps+=("boost")
    fi
    
    # 检查 jsoncpp
    if [ ! -f "/opt/homebrew/include/json/json.h" ] && [ ! -f "/usr/local/include/json/json.h" ]; then
        missing_deps+=("jsoncpp")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "运行 './start.sh setup' 安装依赖"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 初始化环境
setup_environment() {
    log_info "开始初始化环境..."
    
    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        log_error "未检测到 Homebrew"
        log_info "请先安装 Homebrew: https://brew.sh"
        exit 1
    fi
    
    # 安装依赖
    log_info "安装 MySQL..."
    brew install mysql
    
    log_info "安装 Boost..."
    brew install boost
    
    log_info "安装 JSON-CPP..."
    brew install jsoncpp
    
    log_info "安装 Paho MQTT C..."
    brew install paho-mqtt-c
    
    # 启动 MySQL
    log_info "启动 MySQL 服务..."
    brew services start mysql
    sleep 3
    
    # 初始化数据库
    if [ -f "$SCRIPT_DIR/database_init.sql" ]; then
        log_info "初始化数据库..."
        mysql -u root < "$SCRIPT_DIR/database_init.sql" 2>/dev/null || {
            log_warning "数据库初始化可能需要手动执行"
            log_info "请运行: mysql -u root -p < database_init.sql"
        }
        log_success "数据库初始化完成"
    else
        log_warning "未找到 database_init.sql"
    fi
    
    # 编译服务器程序
    log_info "编译 TCP 服务器..."
    cd "$SCRIPT_DIR/BackgroundServer/TCP"
    make clean 2>/dev/null || true
    make
    log_success "TCP 服务器编译完成"
    
    log_info "编译 MQTT 服务器..."
    cd "$SCRIPT_DIR/BackgroundServer/MQTT"
    make clean 2>/dev/null || true
    make
    log_success "MQTT 服务器编译完成"
    
    log_success "环境初始化完成！"
}

# 启动 TCP 服务器
start_tcp_server() {
    if [ -f "$TCP_PID_FILE" ] && kill -0 $(cat "$TCP_PID_FILE") 2>/dev/null; then
        log_warning "TCP 服务器已在运行 (PID: $(cat $TCP_PID_FILE))"
        return
    fi
    
    log_info "启动 TCP 服务器..."
    cd "$SCRIPT_DIR/BackgroundServer/TCP"
    nohup ./main > tcp_server.log 2>&1 &
    echo $! > "$TCP_PID_FILE"
    sleep 2
    
    if kill -0 $(cat "$TCP_PID_FILE") 2>/dev/null; then
        log_success "TCP 服务器已启动 (PID: $(cat $TCP_PID_FILE), Port: 10000)"
    else
        log_error "TCP 服务器启动失败，查看日志: tcp_server.log"
        rm -f "$TCP_PID_FILE"
        exit 1
    fi
}

# 启动 MQTT 服务器
start_mqtt_server() {
    if [ -f "$MQTT_PID_FILE" ] && kill -0 $(cat "$MQTT_PID_FILE") 2>/dev/null; then
        log_warning "MQTT 服务器已在运行 (PID: $(cat $MQTT_PID_FILE))"
        return
    fi
    
    log_info "启动 MQTT 服务器..."
    cd "$SCRIPT_DIR/BackgroundServer/MQTT"
    nohup ./main > mqtt_server.log 2>&1 &
    echo $! > "$MQTT_PID_FILE"
    sleep 2
    
    if kill -0 $(cat "$MQTT_PID_FILE") 2>/dev/null; then
        log_success "MQTT 服务器已启动 (PID: $(cat $MQTT_PID_FILE))"
    else
        log_error "MQTT 服务器启动失败，查看日志: mqtt_server.log"
        rm -f "$MQTT_PID_FILE"
        exit 1
    fi
}

# 停止 TCP 服务器
stop_tcp_server() {
    if [ -f "$TCP_PID_FILE" ]; then
        local pid=$(cat "$TCP_PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            log_info "停止 TCP 服务器 (PID: $pid)..."
            kill $pid
            sleep 1
            log_success "TCP 服务器已停止"
        else
            log_warning "TCP 服务器未运行"
        fi
        rm -f "$TCP_PID_FILE"
    else
        log_warning "未找到 TCP 服务器 PID 文件"
    fi
}

# 停止 MQTT 服务器
stop_mqtt_server() {
    if [ -f "$MQTT_PID_FILE" ]; then
        local pid=$(cat "$MQTT_PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            log_info "停止 MQTT 服务器 (PID: $pid)..."
            kill $pid
            sleep 1
            log_success "MQTT 服务器已停止"
        else
            log_warning "MQTT 服务器未运行"
        fi
        rm -f "$MQTT_PID_FILE"
    else
        log_warning "未找到 MQTT 服务器 PID 文件"
    fi
}

# 查看所有服务状态
show_status() {
    echo ""
    echo "========================================="
    echo "  IoT 项目服务状态"
    echo "========================================="
    echo ""
    
    # MySQL 状态
    if brew services list | grep mysql | grep -q started; then
        echo -e "MySQL:          ${GREEN}● 运行中${NC}"
    else
        echo -e "MySQL:          ${RED}○ 已停止${NC}"
    fi
    
    # TCP 服务器状态
    if [ -f "$TCP_PID_FILE" ] && kill -0 $(cat "$TCP_PID_FILE") 2>/dev/null; then
        echo -e "TCP 服务器:     ${GREEN}● 运行中${NC} (PID: $(cat $TCP_PID_FILE), Port: 10000)"
    else
        echo -e "TCP 服务器:     ${RED}○ 已停止${NC}"
    fi
    
    # MQTT 服务器状态
    if [ -f "$MQTT_PID_FILE" ] && kill -0 $(cat "$MQTT_PID_FILE") 2>/dev/null; then
        echo -e "MQTT 服务器:    ${GREEN}● 运行中${NC} (PID: $(cat $MQTT_PID_FILE))"
    else
        echo -e "MQTT 服务器:    ${RED}○ 已停止${NC}"
    fi
    
    echo ""
    echo "========================================="
    echo ""
}

# 启动所有服务
start_all() {
    log_info "启动所有服务..."
    echo ""
    
    # 检查 MySQL
    if ! brew services list | grep mysql | grep -q started; then
        log_info "启动 MySQL..."
        brew services start mysql
        sleep 3
    fi
    
    start_tcp_server
    start_mqtt_server
    
    echo ""
    log_success "所有服务已启动！"
    echo ""
    show_status
}

# 停止所有服务
stop_all() {
    log_info "停止所有服务..."
    echo ""
    
    stop_tcp_server
    stop_mqtt_server
    
    echo ""
    log_success "所有服务已停止！"
    echo ""
}

# 重启所有服务
restart_all() {
    log_info "重启所有服务..."
    stop_all
    sleep 2
    start_all
}

# 显示帮助信息
show_help() {
    echo ""
    echo "========================================="
    echo "  IoT 项目启动脚本"
    echo "========================================="
    echo ""
    echo "用法: ./start.sh [command]"
    echo ""
    echo "命令:"
    echo "  start     - 启动所有服务"
    echo "  stop      - 停止所有服务"
    echo "  restart   - 重启所有服务"
    echo "  status    - 查看服务状态"
    echo "  setup     - 初始化环境（仅首次运行）"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  ./start.sh setup      # 首次运行，安装依赖"
    echo "  ./start.sh start      # 启动服务"
    echo "  ./start.sh status     # 查看状态"
    echo "  ./start.sh stop       # 停止服务"
    echo ""
    echo "========================================="
    echo ""
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            check_dependencies
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        status)
            show_status
            ;;
        setup)
            setup_environment
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
