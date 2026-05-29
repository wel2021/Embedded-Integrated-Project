#!/bin/bash

# ============================================
# IoT 项目功能测试脚本
# ============================================
# 用法: ./test.sh
# 说明: 测试 TCP 服务器的各项功能
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 服务器配置
SERVER_HOST="127.0.0.1"
SERVER_PORT="10000"

echo ""
echo "========================================="
echo "  IoT 项目功能测试"
echo "========================================="
echo ""

# 检查服务器是否运行
if ! lsof -i :$SERVER_PORT > /dev/null 2>&1; then
    echo -e "${RED}✗ TCP 服务器未运行${NC}"
    echo -e "${YELLOW}请先运行: ./start.sh start${NC}"
    exit 1
fi

echo -e "${GREEN}✓ TCP 服务器正在运行 (Port: $SERVER_PORT)${NC}"
echo ""

# 测试函数
test_command() {
    local test_name=$1
    local json_data=$2
    
    echo -e "${BLUE}测试: $test_name${NC}"
    echo "发送: $json_data"
    
    # 使用 nc 发送数据并接收响应
    response=$(echo "$json_data" | nc -w 3 $SERVER_HOST $SERVER_PORT 2>/dev/null)
    
    if [ -n "$response" ]; then
        echo -e "${GREEN}✓ 收到响应:${NC} $response"
        echo ""
        return 0
    else
        echo -e "${RED}✗ 未收到响应或超时${NC}"
        echo ""
        return 1
    fi
}

# 开始测试
passed=0
failed=0

# 测试 1: 用户注册
echo "-----------------------------------------"
test_command "用户注册" '{"CMD":"注册","ID":"test_user_001","pass":"123456","name":"测试用户","email":"test001@example.com"}'
if [ $? -eq 0 ]; then ((passed++)); else ((failed++)); fi

# 等待一下
sleep 1

# 测试 2: 用户登录
echo "-----------------------------------------"
test_command "用户登录" '{"CMD":"登录","ID":"test_user_001","pass":"123456"}'
if [ $? -eq 0 ]; then ((passed++)); else ((failed++)); fi

sleep 1

# 测试 3: 设备绑定
echo "-----------------------------------------"
test_command "设备绑定" '{"CMD":"绑定","ID":"test_user_001","ChipID":"TEST_CHIP_001","name":"测试设备"}'
if [ $? -eq 0 ]; then ((passed++)); else ((failed++)); fi

sleep 1

# 测试 4: 获取绑定列表
echo "-----------------------------------------"
test_command "获取绑定列表" '{"CMD":"获取绑定","ID":"test_user_001"}'
if [ $? -eq 0 ]; then ((passed++)); else ((failed++)); fi

sleep 1

# 测试 5: 查询设备状态
echo "-----------------------------------------"
test_command "查询设备状态" '{"CMD":"状态","ChipID":"TEST_CHIP_001"}'
if [ $? -eq 0 ]; then ((passed++)); else ((failed++)); fi

# 测试结果汇总
echo ""
echo "========================================="
echo "  测试结果汇总"
echo "========================================="
echo ""
echo -e "通过: ${GREEN}$passed${NC}"
echo -e "失败: ${RED}$failed${NC}"
echo -e "总计: $((passed + failed))"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！${NC}"
else
    echo -e "${YELLOW}⚠ 部分测试失败，请检查服务器日志${NC}"
fi

echo ""
echo "========================================="
echo ""

# 清理测试数据提示
echo -e "${YELLOW}提示: 测试完成后，建议清理测试数据${NC}"
echo "mysql -u root -p myproject -e \"DELETE FROM user WHERE ID='test_user_001';\""
echo ""
