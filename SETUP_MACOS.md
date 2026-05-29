# macOS 环境配置指南

本指南帮助你在 macOS 系统上搭建完整的 IoT 项目开发环境。

## 📋 系统要求

- **操作系统**: macOS 10.15+ (Catalina 或更高版本)
- **处理器**: Intel 或 Apple Silicon (M1/M2/M3)
- **内存**: 至少 8GB RAM
- **磁盘空间**: 至少 10GB 可用空间

## 🔧 安装步骤

### 1. 安装 Homebrew（包管理器）

如果尚未安装 Homebrew，打开终端运行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

验证安装：
```bash
brew --version
```

### 2. 安装开发工具

#### 2.1 安装 Xcode Command Line Tools

```bash
xcode-select --install
```

#### 2.2 安装编译器

```bash
brew install gcc
```

### 3. 安装数据库 - MySQL

#### 3.1 安装 MySQL

```bash
brew install mysql
```

#### 3.2 启动 MySQL 服务

```bash
# 启动服务
brew services start mysql

# 检查状态
brew services list | grep mysql
```

#### 3.3 初始化 MySQL

首次安装后，设置 root 密码：

```bash
mysql_secure_installation
```

按照提示：
- 设置 root 密码
- 移除匿名用户
- 禁止远程 root 登录（开发环境可选）
- 移除测试数据库
- 重新加载权限表

#### 3.4 创建项目数据库

```bash
# 登录 MySQL
mysql -u root -p

# 执行初始化脚本
source /path/to/database_init.sql

# 退出
exit;
```

或者一行命令：
```bash
mysql -u root -p < database_init.sql
```

#### 3.5 配置远程访问（可选）

如果需要从其他机器访问数据库：

```sql
-- 登录 MySQL
mysql -u root -p

-- 创建远程访问用户
CREATE USER 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON myproject.* TO 'admin'@'%';
FLUSH PRIVILEGES;

-- 修改 MySQL 配置文件
nano /opt/homebrew/etc/my.cnf

# 注释或修改 bind-address
# bind-address = 127.0.0.1
bind-address = 0.0.0.0

# 重启 MySQL
brew services restart mysql
```

### 4. 安装 Boost 库

Boost.Asio 用于跨平台网络编程：

```bash
brew install boost
```

验证安装：
```bash
ls /opt/homebrew/include/boost/asio.hpp
```

### 5. 安装 JSON-CPP

用于 JSON 数据解析：

```bash
brew install jsoncpp
```

### 6. 安装 MySQL 客户端开发库

```bash
# MySQL 客户端库已包含在 mysql 安装中
# 验证头文件存在
ls /opt/homebrew/include/mysql/mysql.h
```

### 7. 安装 MQTT 库（Paho MQTT C）

用于 MQTT 服务器端：

```bash
brew install paho-mqtt-c
```

验证：
```bash
ls /opt/homebrew/include/MQTTClient.h
```

### 8. 安装 Qt 5.9.9（上位机开发）

#### 8.1 下载 Qt

访问 [Qt Archive](https://download.qt.io/archive/qt/5.9/5.9.9/) 下载：
- `qt-opensource-mac-x64-5.9.9.dmg`

#### 8.2 安装 Qt

双击 DMG 文件，按照向导安装。选择组件：
- ✅ Qt 5.9.9
- ✅ Qt Creator
- ✅ macOS 组件

#### 8.3 配置环境变量

编辑 `~/.zshrc`：

```bash
nano ~/.zshrc
```

添加：
```bash
export QT_DIR=/Users/your_username/Qt5.9.9
export PATH=$QT_DIR/clang_64/bin:$PATH
```

重新加载：
```bash
source ~/.zshrc
```

验证：
```bash
qmake --version
```

## 🚀 编译和运行项目

### 1. TCP 后台服务器

```bash
cd BackgroundServer/TCP

# 编译
make

# 运行
./main
```

预期输出：
```
数据库连接成功！
连接mysql数据库成功
Server running on port 10000...
```

### 2. MQTT 后台服务器

```bash
cd BackgroundServer/MQTT

# 编译
make

# 运行
./main
```

预期输出：
```
数据库连接成功！
连接MQTT成功
10秒发送一次心跳包
```

### 3. Qt 上位机客户端

```bash
cd Qt/smart_home

# 使用 Qt Creator 打开项目
open smart_home.pro

# 或在命令行编译
qmake smart_home.pro
make

# 运行
./smart_home.app/Contents/MacOS/smart_home
```

## 🧪 测试连接

### 测试 TCP 服务器

```bash
# 终端 1: 启动服务器
cd BackgroundServer/TCP && ./main

# 终端 2: 使用 nc 测试
nc 127.0.0.1 10000

# 发送注册请求
{"CMD":"注册","ID":"test001","pass":"123456","name":"测试","email":"test@test.com"}

# 发送登录请求
{"CMD":"登录","ID":"test001","pass":"123456"}
```

### 测试数据库连接

```bash
mysql -u admin -p myproject

# 查询用户
SELECT * FROM user;

# 查询设备绑定
SELECT * FROM user_chip;

# 退出
exit;
```

## ⚙️ 配置说明

### TCP 服务器配置

编辑 `BackgroundServer/TCP/main.cpp`：

```cpp
// 修改数据库连接信息
MYSQL *ret = mysql_real_connect(&mysql, 
    "127.0.0.1",      // 数据库地址（本地用 127.0.0.1）
    "admin",          // 用户名
    "admin123",       // 密码
    NULL,             // 数据库名
    3306,             // 端口
    NULL, 0);

// 修改监听端口
TcpServer server(io_context, 10000, mysql);  // 端口号
```

### MQTT 服务器配置

编辑 `BackgroundServer/MQTT/main.cpp`：

```cpp
// 修改 MQTT 服务器地址
MQTTClient_create(&clinet, "mqtt.yyzlab.com.cn", "client_id", 1, NULL);

// 修改订阅主题
MQTTClient_subscribe(clinet, "Your_ChipID", 1);
```

### Qt 客户端配置

编辑 Qt 项目中的连接配置（通常在 `login.cpp` 或配置文件）：

```cpp
// TCP 服务器地址
QString serverIP = "127.0.0.1";  // 本地测试
int serverPort = 10000;

// MQTT 配置
QString mqttBroker = "mqtt.yyzlab.com.cn";
```

## 🐛 常见问题

### 1. 找不到头文件

**错误**: `fatal error: 'boost/asio.hpp' file not found`

**解决**:
```bash
brew install boost
```

### 2. 链接库失败

**错误**: `ld: library 'jsoncpp' not found`

**解决**:
```bash
brew install jsoncpp
# 确认库路径
ls /opt/homebrew/lib/libjsoncpp*
```

### 3. MySQL 连接失败

**错误**: `Can't connect to MySQL server`

**检查**:
```bash
# 确认 MySQL 正在运行
brew services list | grep mysql

# 检查端口
lsof -i :3306

# 重启服务
brew services restart mysql
```

### 4. 权限问题

**错误**: `Permission denied`

**解决**:
```bash
# 给可执行文件添加执行权限
chmod +x main
```

### 5. 端口被占用

**错误**: `Address already in use`

**解决**:
```bash
# 查找占用端口的进程
lsof -i :10000

# 终止进程
kill -9 <PID>
```

### 6. Apple Silicon (M1/M2) 兼容性问题

如果遇到架构不匹配：

```bash
# 确保使用 ARM64 版本的库
arch -arm64 brew install boost

# 编译时指定架构
g++ -arch arm64 main.cpp -o main
```

## 📊 性能优化建议

### 1. 数据库优化

定期清理历史数据：

```sql
-- 创建定时事件（MySQL 8.0+）
CREATE EVENT cleanup_old_data
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DELETE FROM device_tem WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
    DELETE FROM device_hum WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
    DELETE FROM device_light WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
END;
```

### 2. 添加索引

SQL 脚本已包含必要索引，如需额外优化：

```sql
-- 为常用查询添加复合索引
ALTER TABLE device_tem ADD INDEX idx_chip_time (ChipID, _time);
ALTER TABLE device_hum ADD INDEX idx_chip_time (ChipID, _time);
```

### 3. TCP 服务器多线程

修改 `BackgroundServer/TCP/main.cpp`：

```cpp
// 使用线程池提高并发性能
std::vector<std::thread> threads;
for (int i = 0; i < 4; ++i) {
    threads.emplace_back([&io_context]() {
        io_context.run();
    });
}
for (auto& t : threads) {
    t.join();
}
```

## 📝 开发工具推荐

### 代码编辑器

- **Visual Studio Code**: 轻量级，插件丰富
  ```bash
  brew install --cask visual-studio-code
  ```
  
- **CLion**: JetBrains C++ IDE（付费）

### 数据库管理

- **TablePlus**: 现代化数据库客户端
  ```bash
  brew install --cask tableplus
  ```

- **MySQL Workbench**: Oracle 官方工具

### API 测试

- **Postman**: API 测试工具
  ```bash
  brew install --cask postman
  ```

### 终端增强

- **iTerm2**: 替代 Terminal
  ```bash
  brew install --cask iterm2
  ```

## 🎓 学习资源

- [Boost.Asio 文档](https://www.boost.org/doc/libs/release/doc/html/asio.html)
- [Qt 官方文档](https://doc.qt.io/qt-5/)
- [MySQL 参考手册](https://dev.mysql.com/doc/)
- [MQTT 协议规范](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html)

## 📞 获取帮助

遇到问题？

1. 查看项目 README.md
2. 检查日志输出
3. 搜索错误信息
4. 提交 Issue

---

**最后更新**: 2026-05-29  
**测试环境**: macOS Sonoma 14.8.7 (Apple Silicon)
