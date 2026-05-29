# 📝 项目使用快速指南

本文档提供 IoT 智能环境监控系统的快速上手指南，帮助你快速开始使用。

## 🎯 5 分钟快速体验

### 前提条件

- macOS 系统（或 Linux）
- 已安装 Homebrew
- 网络连接

### 步骤 1: 克隆项目

```bash
git clone https://github.com/your_username/Embedded-Integrated-Project.git
cd Embedded-Integrated-Project
```

### 步骤 2: 一键初始化

```bash
./start.sh setup
```

这个命令会自动：
- ✅ 安装 MySQL、Boost、JSON-CPP 等依赖
- ✅ 启动 MySQL 服务
- ✅ 创建数据库和表结构
- ✅ 编译 TCP 和 MQTT 服务器

预计耗时：3-5 分钟（取决于网络速度）

### 步骤 3: 启动服务

```bash
./start.sh start
```

你会看到类似输出：
```
[INFO] 启动所有服务...
[SUCCESS] TCP 服务器已启动 (PID: 12345, Port: 10000)
[SUCCESS] MQTT 服务器已启动 (PID: 12346)

=========================================
  IoT 项目服务状态
=========================================

MySQL:          ● 运行中
TCP 服务器:     ● 运行中 (PID: 12345, Port: 10000)
MQTT 服务器:    ● 运行中 (PID: 12346)

=========================================
```

### 步骤 4: 测试功能

```bash
./test.sh
```

这会测试：
- 用户注册
- 用户登录
- 设备绑定
- 数据查询

### 步骤 5: 运行 Qt 客户端（可选）

如果你有 Qt 开发环境：

```bash
cd Qt/smart_home
qmake smart_home.pro
make
open smart_home.app
```

---

## 📖 常用操作

### 查看服务状态

```bash
./start.sh status
```

### 重启服务

```bash
./start.sh restart
```

### 停止服务

```bash
./start.sh stop
```

### 查看日志

```bash
# TCP 服务器日志
tail -f BackgroundServer/TCP/tcp_server.log

# MQTT 服务器日志
tail -f BackgroundServer/MQTT/mqtt_server.log
```

### 连接数据库

```bash
mysql -u root -p myproject

# 常用查询
SHOW TABLES;
SELECT * FROM user;
SELECT * FROM user_chip;
```

---

## 🧪 手动测试 TCP 服务器

### 使用 netcat 测试

```bash
# 连接到服务器
nc 127.0.0.1 10000

# 发送注册请求
{"CMD":"注册","ID":"myuser","pass":"123456","name":"我的名字","email":"my@example.com"}

# 等待响应后，发送登录请求
{"CMD":"登录","ID":"myuser","pass":"123456"}

# 绑定设备
{"CMD":"绑定","ID":"myuser","ChipID":"TEST001","name":"测试设备"}

# 获取绑定列表
{"CMD":"获取绑定","ID":"myuser"}

# 查询状态
{"CMD":"状态","ChipID":"TEST001"}

# 按 Ctrl+D 断开连接
```

### 预期响应

*注册响应*:
```json
{
   "CMD" : "注册结果",
   "State" : true
}
```

*登录响应*:
```json
{
   "CMD" : "登录结果",
   "State" : true
}
```

*绑定列表响应*:
```json
{
   "CMD" : "绑定列表",
   "list" : [
      {
         "芯片ID" : "TEST001",
         "备注" : "测试设备"
      }
   ]
}
```

*状态查询响应*:
```json
{
   "CMD" : "状态更新",
   "hum" : 60.5,
   "tem" : 25.3,
   "light" : 1024.0,
   "led3" : 0,
   "beep" : 0,
   "fan" : 0
}
```

---

## 🔍 故障排查

### 问题 1: 服务启动失败

**检查端口占用**:
```bash
lsof -i :10000
```

如果有进程占用，终止它：
```bash
kill -9 <PID>
```

**检查 MySQL 是否运行**:
```bash
brew services list | grep mysql
```

如果没有运行：
```bash
brew services start mysql
```

### 问题 2: 数据库连接失败

**验证数据库存在**:
```bash
mysql -u root -p -e "SHOW DATABASES;" | grep myproject
```

如果不存在，重新初始化：
```bash
mysql -u root -p < database_init.sql
```

**检查数据库配置**:

编辑 `BackgroundServer/TCP/main.cpp`，确认连接信息：
```cpp
MYSQL *ret = mysql_real_connect(&mysql, 
    "127.0.0.1",    // 确保地址正确
    "root",         // 用户名
    "your_password",// 密码
    NULL, 
    3306, 
    NULL, 0);
```

### 问题 3: 编译错误

**缺少头文件**:
```bash
# 检查 Boost
ls /opt/homebrew/include/boost/asio.hpp

# 检查 jsoncpp
ls /opt/homebrew/include/json/json.h

# 如果缺失，重新安装
brew install boost jsoncpp
```

**库链接失败**:
```bash
# 检查库文件
ls /opt/homebrew/lib/libjsoncpp*
ls /opt/homebrew/lib/libmysqlclient*
```

### 问题 4: Qt 客户端无法连接

**检查防火墙**:
```bash
# macOS 系统偏好设置 -> 安全性与隐私 -> 防火墙
# 确保允许 Qt 应用联网
```

**检查服务器地址**:

在 Qt 项目中确认服务器 IP：
```cpp
QString serverIP = "127.0.0.1";  // 本地测试
int port = 10000;
```

---

## 📊 数据库快速查询

### 查看所有用户

```sql
SELECT ID, name, email FROM user;
```

### 查看设备绑定关系

```sql
SELECT uc.ID, uc.ChipID, uc.name, u.name as owner
FROM user_chip uc
JOIN user u ON uc.ID = u.ID;
```

### 查看最新传感器数据

```sql
-- 温度
SELECT ChipID, _value as temperature, FROM_UNIXTIME(_time) as time
FROM device_tem
ORDER BY _time DESC
LIMIT 10;

-- 湿度
SELECT ChipID, _value as humidity, FROM_UNIXTIME(_time) as time
FROM device_hum
ORDER BY _time DESC
LIMIT 10;
```

### 统计某设备数据量

```sql
SELECT 
    COUNT(*) as total_records,
    MIN(FROM_UNIXTIME(_time)) as earliest,
    MAX(FROM_UNIXTIME(_time)) as latest
FROM device_tem
WHERE ChipID = '511757085';
```

### 清理测试数据

```sql
-- 删除测试用户及其相关数据
DELETE FROM user WHERE ID LIKE 'test%';
DELETE FROM user_chip WHERE ID LIKE 'test%';
DELETE FROM chip WHERE ChipID LIKE 'TEST%';
```

---

## 🎓 学习路径

### 第 1 天：理解架构

1. 阅读 [ARCHITECTURE.md](ARCHITECTURE.md)
2. 了解 TCP 和 MQTT 的区别
3. 理解数据流向

### 第 2 天：运行系统

1. 按照本指南启动所有服务
2. 使用 netcat 测试 TCP 接口
3. 查看数据库中的数据变化

### 第 3 天：深入代码

1. 阅读 `BackgroundServer/TCP/main.cpp`
2. 理解 Boost.Asio 的异步模型
3. 分析 JSON 处理逻辑

### 第 4 天：扩展功能

1. 添加新的传感器类型
2. 实现数据可视化图表
3. 集成语音识别功能

---

## 💡 最佳实践

### 1. 定期备份数据库

```bash
# 备份
mysqldump -u root -p myproject > backup_$(date +%Y%m%d).sql

# 恢复
mysql -u root -p myproject < backup_20260529.sql
```

### 2. 监控服务器性能

```bash
# 查看 TCP 服务器资源占用
ps aux | grep "TCP/main"

# 查看 MySQL 连接数
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
```

### 3. 日志轮转

创建 `/etc/newsyslog.d/iot.conf`:
```
/tmp/iot_tcp.log  644  7  100  *  J
/tmp/iot_mqtt.log 644  7  100  *  J
```

### 4. 安全加固

- 修改默认数据库密码
- 启用防火墙规则
- 使用 HTTPS/WSS 加密通信
- 实施速率限制

---

## 📞 获取帮助

### 文档

- [完整 README](README.md)
- [macOS 配置指南](SETUP_MACOS.md)
- [系统架构详解](ARCHITECTURE.md)

### 社区

- GitHub Issues: 提交问题和bug报告
- Stack Overflow: 搜索技术问题
- Qt Forum: Qt 相关问题

### 调试技巧

**启用详细日志**:

修改代码添加调试输出：
```cpp
cout << "DEBUG: Received message: " << buf << endl;
```

**使用 gdb 调试**:
```bash
gdb ./main
(gdb) run
(gdb) bt  # 崩溃时查看堆栈
```

**网络抓包**:
```bash
# 捕获 TCP 流量
sudo tcpdump -i lo0 port 10000 -X

# 捕获 MQTT 流量
sudo tcpdump -i en0 port 1883 -X
```

---

## 🎉 下一步

恭喜！你已经成功运行了 IoT 智能环境监控系统。接下来可以：

1. **部署到云服务器** - 让系统 24/7 运行
2. **添加更多设备** - 扩展监控范围
3. **开发移动应用** - iOS/Android 客户端
4. **实现自动化** - 基于规则的自动控制
5. **数据分析** - 机器学习预测趋势

祝你玩得开心！🚀

---

**最后更新**: 2026-05-29  
**维护者**: 括号侠
