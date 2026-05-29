# TCP 后台服务器 - Boost.Asio 跨平台版本

## 📋 项目说明

这是一个基于 Boost.Asio 实现的跨平台 TCP 服务器，支持 IoT 设备管理功能。

### 主要功能
- 用户注册/登录
- 设备芯片绑定
- 实时状态查询（温度、湿度、光照等）
- 跨平台支持（macOS、Linux、Windows）

## 🛠️ 环境要求

### macOS
```bash
# 安装 Boost 库
brew install boost

# 安装 MySQL 客户端库
brew install mysql-client

# 安装 jsoncpp
brew install jsoncpp
```

### Linux (Ubuntu/Debian)
```bash
# 安装依赖
sudo apt-get install libboost-dev libboost-system-dev
sudo apt-get install libmysqlclient-dev
sudo apt-get install libjsoncpp-dev
```

## 🚀 编译与运行

### 编译
```bash
cd BackgroundServer/TCP
make
```

### 运行
```bash
./main
```

服务器将在端口 **10000** 上启动并监听连接。

## 🧪 测试

你可以使用 `nc` (netcat) 命令测试服务器：

```bash
# 连接到服务器
nc 127.0.0.1 10000

# 发送注册请求
{"CMD":"注册","ID":"10000","pass":"123456","name":"测试用户","email":"test@example.com"}

# 发送登录请求
{"CMD":"登录","ID":"10000","pass":"123456"}
```

## 📡 支持的命令

### 1. 注册
```json
{
    "CMD": "注册",
    "ID": "10000",
    "pass": "123456",
    "name": "用户名",
    "email": "email@example.com"
}
```

### 2. 登录
```json
{
    "CMD": "登录",
    "ID": "10000",
    "pass": "123456"
}
```

### 3. 绑定设备
```json
{
    "CMD": "绑定",
    "ID": "10000",
    "ChipID": "1516DC4611515D6516",
    "name": "一号教室"
}
```

### 4. 获取绑定列表
```json
{
    "CMD": "获取绑定",
    "ID": "10000"
}
```

### 5. 查询设备状态
```json
{
    "CMD": "状态",
    "ChipID": "1516DC4611515D6516"
}
```

## 🔧 技术架构

### 核心组件

1. **TcpServer**: 服务器类，负责监听端口和接受新连接
2. **Session**: 会话类，处理单个客户端的所有通信
3. **业务逻辑函数**: 
   - `tcp_regist()`: 用户注册
   - `tcp_login()`: 用户登录
   - `tcp_bind()`: 设备绑定
   - `tcp_get_bind()`: 获取绑定列表
   - `tcp_ret_state()`: 查询设备状态

### 跨平台实现

Boost.Asio 会自动在不同平台上使用最优的 I/O 多路复用机制：

| 平台 | 底层实现 |
|------|---------|
| macOS | kqueue |
| Linux | epoll |
| Windows | IOCP |

## 📝 代码结构

```
BackgroundServer/TCP/
├── main.cpp      # 主程序文件（Boost.Asio 实现）
├── main.h        # 头文件（函数声明）
└── Makefile      # 编译配置
```

## ⚙️ 数据库配置

在 `connectDB()` 函数中配置数据库连接信息：

```cpp
MYSQL *ret = mysql_real_connect(&mysql, 
    "127.0.0.1",  // 数据库地址
    "admin",           // 用户名
    "admin123",        // 密码
    NULL,              // 数据库名（稍后切换）
    3306,              // 端口
    NULL, 0);
```

## 🎯 优势

✅ **跨平台**: 一套代码在所有平台运行  
✅ **高性能**: 异步 I/O，支持高并发  
✅ **易维护**: 无需条件编译宏  
✅ **现代化**: 使用 C++11 标准  

## 📌 注意事项

1. 确保数据库已创建并包含必要的表结构
2. 首次运行前需要安装所有依赖库
3. 防火墙需要允许 10000 端口的连接
4. 生产环境建议修改默认数据库密码

## 🔍 故障排查

### 编译错误：找不到 boost/asio.hpp
```bash
# macOS
brew install boost

# Linux
sudo apt-get install libboost-dev
```

### 运行时错误：无法连接数据库
- 检查数据库服务是否运行
- 验证网络连接
- 确认数据库凭据正确

### 端口被占用
修改 `main()` 中的端口号：
```cpp
TcpServer server(io_context, 10000, mysql);  // 改为其他端口
```