# 📚 文档导航

欢迎使用 IoT 智能环境监控系统！本文档索引帮助你快速找到所需信息。

## 🚀 新手入门

### 我想快速体验系统

👉 [**快速使用指南 (QUICKSTART.md)**](QUICKSTART.md)
- 5 分钟快速启动
- 常用操作命令
- 手动测试方法
- 故障排查

### 我要在 macOS 上搭建开发环境

👉 [**macOS 环境配置 (SETUP_MACOS.md)**](SETUP_MACOS.md)
- Homebrew 安装
- MySQL 配置
- Boost、JSON-CPP 安装
- Qt 5.9.9 安装
- 编译和运行
- 常见问题解决

### 我想了解系统架构

👉 [**系统架构详解 (ARCHITECTURE.md)**](ARCHITECTURE.md)
- 整体架构图
- 通信协议详解
- 数据库设计
- 模块详细设计
- 数据流示例
- 性能优化建议

---

## 📖 分模块文档

### 后台服务器

#### TCP 服务器
- [TCP 服务器 README](BackgroundServer/TCP/README.md) - API 文档和使用说明
- [迁移总结](BackgroundServer/TCP/MIGRATION_SUMMARY.md) - 从 epoll 到 Boost.Asio

**源代码**:
- [`BackgroundServer/TCP/main.cpp`](BackgroundServer/TCP/main.cpp) - 主程序
- [`BackgroundServer/TCP/main.h`](BackgroundServer/TCP/main.h) - 头文件

#### MQTT 服务器
- [`BackgroundServer/MQTT/main.cpp`](BackgroundServer/MQTT/main.cpp) - MQTT 服务端

### 上位机客户端

#### Qt 项目
- **主项目**: [`Qt/smart_home/`](Qt/smart_home/)
  - `login.cpp/h` - 登录界面
  - `regist.cpp/h` - 注册界面
  - `func.cpp/h` - 主功能界面
  - `dial.cpp/h` - 仪表盘控件
  - `switchbutton.cpp/h` - 开关按钮

#### QtMqtt 模块
- **源码**: [`Qt/qtmqtt-5.15/`](Qt/qtmqtt-5.15/)

### 下位机固件

#### STM32F407
- **主程序**: [`STM32F407/USER/main.c`](STM32F407/USER/main.c)
- **硬件驱动**: [`STM32F407/HARTDWARE/`](STM32F407/HARTDWARE/)
  - `ADC/` - 模数转换
  - `DHT11/` - 温湿度传感器
  - `OLED/` - OLED 显示
  - `UART/` - 串口通信（ESP8266）
  - `IIC/` - I2C 总线
  - `cJSON/` - JSON 解析库

---

## 🗄️ 数据库

### SQL 脚本
- [**数据库初始化脚本 (database_init.sql)**](database_init.sql)
  - 完整的表结构定义
  - 测试数据
  - 查询示例
  - 性能优化建议

### 表结构概览

| 表名 | 说明 | 用途 |
|------|------|------|
| `user` | 用户信息 | 存储注册用户 |
| `user_chip` | 设备绑定 | 用户与设备的关联 |
| `chip` | 芯片注册 | 记录所有设备 |
| `device_tem` | 温度数据 | 温度传感器历史数据 |
| `device_hum` | 湿度数据 | 湿度传感器历史数据 |
| `device_light` | 光照数据 | 光照传感器历史数据 |
| `device_led3` | LED 状态 | LED 控制记录 |
| `device_beep` | 蜂鸣器状态 | 蜂鸣器控制记录 |
| `device_fan` | 风扇状态 | 风扇 PWM 记录 |

---

## 🛠️ 工具脚本

### start.sh - 服务管理脚本

```bash
./start.sh setup      # 初始化环境（首次运行）
./start.sh start      # 启动所有服务
./start.sh stop       # 停止所有服务
./start.sh restart    # 重启所有服务
./start.sh status     # 查看服务状态
./start.sh help       # 显示帮助
```

**功能**:
- ✅ 自动安装依赖
- ✅ 编译服务器程序
- ✅ 启动/停止服务
- ✅ 进程管理
- ✅ 日志记录

### test.sh - 自动化测试脚本

```bash
./test.sh             # 运行所有功能测试
```

**测试内容**:
- 用户注册
- 用户登录
- 设备绑定
- 获取绑定列表
- 查询设备状态

---

## 📋 API 参考

### TCP API

**连接信息**:
- 主机: `127.0.0.1` (本地) 或服务器 IP
- 端口: `10000`
- 协议: TCP
- 格式: JSON

**支持的命令**:

#### 1. 用户注册
```json
请求: {"CMD":"注册","ID":"user001","pass":"123456","name":"张三","email":"zhang@example.com"}
响应: {"CMD":"注册结果","State":true}
```

#### 2. 用户登录
```json
请求: {"CMD":"登录","ID":"user001","pass":"123456"}
响应: {"CMD":"登录结果","State":true}
```

#### 3. 绑定设备
```json
请求: {"CMD":"绑定","ID":"user001","ChipID":"511757085","name":"客厅设备"}
响应: {"CMD":"绑定结果","State":true}
```

#### 4. 获取绑定列表
```json
请求: {"CMD":"获取绑定","ID":"user001"}
响应: {
  "CMD":"绑定列表",
  "list":[
    {"芯片ID":"511757085","备注":"客厅设备"}
  ]
}
```

#### 5. 查询设备状态
```json
请求: {"CMD":"状态","ChipID":"511757085"}
响应: {
  "CMD":"状态更新",
  "tem":25.6,
  "hum":60.2,
  "light":1024.0,
  "led3":1,
  "beep":0,
  "fan":50
}
```

### MQTT API

**Broker 地址**: `mqtt.yyzlab.com.cn`  
**端口**: `1883` (TCP) / `8883` (TLS)

**主题命名**:
- 上传: `{ChipID}` 
- 控制: `{ChipID}/control`

**数据格式**:

*上传传感器数据*:
```json
{
  "ChipID": "511757085",
  "tem": 25.6,
  "hum": 60.2,
  "light": 1024,
  "beep": 0,
  "fan": 50,
  "led3": 1
}
```

*下发控制指令*:
```json
{
  "CMD": "control",
  "device": "fan",
  "value": 80
}
```

---

## 🔍 常见问题分类

### 安装问题
- [如何安装 Homebrew?](SETUP_MACOS.md#1-安装-homebrew包管理器)
- [MySQL 安装失败怎么办?](SETUP_MACOS.md#3-安装数据库---mysql)
- [Boost 库找不到?](SETUP_MACOS.md#4-安装-boost-库)

### 编译问题
- [编译时提示缺少头文件](SETUP_MACOS.md#1-找不到头文件)
- [链接库失败](SETUP_MACOS.md#2-链接库失败)
- [Apple Silicon 兼容性问题](SETUP_MACOS.md#6-apple-silicon-m1m2-兼容性问题)

### 运行时问题
- [数据库连接失败](QUICKSTART.md#问题-2-数据库连接失败)
- [端口被占用](QUICKSTART.md#问题-1-服务启动失败)
- [Qt 客户端无法连接](QUICKSTART.md#问题-4-qt-客户端无法连接)

### 开发问题
- [如何添加新的传感器类型?](ARCHITECTURE.md#-扩展方向)
- [如何优化数据库性能?](ARCHITECTURE.md#1-数据库优化)
- [如何实现多线程?](BackgroundServer/TCP/README.md#🎯-下一步建议)

---

## 📊 学习路线图

### 初级（1-2 周）

**目标**: 能够运行和理解系统

1. ✅ 阅读 [README.md](README.md) 了解项目概况
2. ✅ 按照 [QUICKSTART.md](QUICKSTART.md) 启动系统
3. ✅ 使用 netcat 测试 TCP API
4. ✅ 查看数据库中的数据变化
5. ✅ 阅读 [ARCHITECTURE.md](ARCHITECTURE.md) 理解架构

### 中级（2-4 周）

**目标**: 能够修改和扩展功能

1. ✅ 阅读 TCP 服务器源代码
2. ✅ 理解 Boost.Asio 异步模型
3. ✅ 添加一个新的 TCP 命令
4. ✅ 修改数据库表结构
5. ✅ 调试和解决常见问题

### 高级（1-2 月）

**目标**: 能够独立开发完整功能

1. ✅ 实现数据缓存机制
2. ✅ 添加 WebSocket 支持
3. ✅ 实现用户权限管理
4. ✅ 部署到云服务器
5. ✅ 性能优化和压力测试

---

## 🎓 相关资源

### 技术文档

- [Boost.Asio 官方文档](https://www.boost.org/doc/libs/release/doc/html/asio.html)
- [Qt 5 文档](https://doc.qt.io/qt-5/)
- [MySQL 参考手册](https://dev.mysql.com/doc/)
- [MQTT 协议规范 v3.1.1](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html)
- [JSON 规范](https://www.json.org/json-en.html)

### 教程

- [Boost.Asio 入门教程](https://think-async.com/Asio/asio-1.28.0/doc/asio/tutorial.html)
- [Qt 官方示例](https://doc.qt.io/qt-5/examples.html)
- [MySQL 最佳实践](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

### 社区

- [Stack Overflow - C++](https://stackoverflow.com/questions/tagged/c%2b%2b)
- [Qt Forum](https://forum.qt.io/)
- [Reddit - r/cpp](https://www.reddit.com/r/cpp/)
- [GitHub Community](https://github.community/)

---

## 📞 需要帮助？

### 提交 Issue

在 GitHub 上创建 Issue 时，请包含：
1. 问题描述
2. 复现步骤
3. 预期行为
4. 实际行为
5. 环境信息（OS、编译器版本等）
6. 相关日志

### 联系方式

- 📧 Email: your_email@example.com
- 💬 Issues: [GitHub Issues](https://github.com/your_username/Embedded-Integrated-Project/issues)
- 🌐 Blog: [你的博客链接]

---

## 📝 文档贡献

欢迎改进文档！如果你发现：
- 错别字或语法错误
- 不清晰的说明
- 缺失的信息
- 过时的内容

请提交 Pull Request 或创建 Issue。

---

<div align="center">

**祝你使用愉快！** 🎉

Made with ❤️ by 括号侠

</div>
