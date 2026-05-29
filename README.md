# 🌐 IoT 智能环境监控系统 - 嵌入式综合项目

<div align="center">

![Platform](https://img.shields.io/badge/platform-STM32F407-blue)
![Qt](https://img.shields.io/badge/Qt-5.9.9-green)
![MySQL](https://img.shields.io/badge/MySQL-5.7+-orange)
![License](https://img.shields.io/badge/license-MIT-red)
![macOS](https://img.shields.io/badge/macOS-Supported-lightgrey)

**基于 STM32 + Qt + MQTT + MySQL 的完整物联网解决方案**

[项目介绍](#-项目介绍) • [系统架构](#-系统架构) • [快速开始](#-快速开始) • [文档](#-文档) • [许可证](#-许可证)

</div>

---

## 📖 项目介绍

这是一个功能完整的 **IoT 智能环境监控系统**，实现了从下位机传感器数据采集、无线传输、云端存储到上位机可视化展示的完整链路。

### ✨ 核心特性

- 🔄 **实时数据采集**: 温度、湿度、光照强度等多传感器融合
- 📡 **双协议通信**: TCP（用户管理）+ MQTT（设备控制）
- 💾 **云端数据存储**: MySQL 数据库持久化，支持历史数据查询
- 🎨 **可视化界面**: Qt 动态曲线图、设备控制面板
- 🎙️ **语音控制**: 集成百度语音识别 API
- 🌤️ **天气服务**: HTTP 获取实时天气预报
- 🔐 **多用户系统**: 用户注册/登录、设备绑定管理
- 📱 **跨平台支持**: macOS、Windows、Linux 全平台兼容

### 🖼️ 界面预览

#### Qt 客户端界面
<img src="res/qt.png" width="600px" alt="Qt客户端界面">

#### STM32 开发板
<img src="res/stm.jpg" width="500px" alt="STM32开发板">

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                      云端服务器 (Linux/macOS)                 │
├──────────────────────┬──────────────────────────────────────┤
│   TCP 服务器          │   MQTT 服务器                         │
│   (Boost.Asio)       │   (Paho MQTT)                        │
│   - 用户认证          │   - 接收设备数据                       │
│   - 设备绑定          │   - 数据解析                           │
│   - 数据查询          │   - 写入 MySQL                        │
│   Port: 10000        │   Broker: mqtt.yyzlab.com.cn         │
└──────────┬───────────┴────────────┬─────────────────────────┘
           │                        │
     ┌─────▼─────┐            ┌────▼──────┐
     │  MySQL    │◄───────────┤  数据存储  │
     │ Database  │            │           │
     └───────────┘            └───────────┘
           ▲                        ▲
           │                        │
    ┌──────┴──────┐          ┌─────┴──────────┐
    │  Qt 客户端   │          │  STM32 下位机   │
    │  (TCP+MQTT) │          │  + ESP8266     │
    │             │          │                │
    │ - 数据展示   │          │ - DHT11 温湿度 │
    │ - 设备控制   │          │ - 光敏传感器    │
    │ - 语音识别   │          │ - LED/风扇/蜂鸣 │
    │ - 天气预报   │          │ - OLED 显示     │
    └─────────────┘          └────────────────┘
```

### 📊 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **下位机** | STM32F407 (ARM Cortex-M4) | 主控芯片 |
| | ESP8266 (MQTT SDK) | WiFi 通信模块 |
| | DHT11 | 温湿度传感器 |
| | 光敏电阻 | 光照强度检测 |
| | OLED (I2C) | 本地显示 |
| | AT24C02 | EEPROM 掉电保护 |
| **上位机** | Qt 5.9.9 | 跨平台 GUI 框架 |
| | QtMqtt | MQTT 客户端库 |
| | QCustomPlot | 动态曲线图 |
| | 百度语音 API | 语音识别 |
| | HTTP/QNetworkAccessManager | 天气查询 |
| **服务器** | Boost.Asio | 跨平台 TCP 服务器 |
| | Paho MQTT C | MQTT 服务端 |
| | JSON-CPP | JSON 数据解析 |
| | MySQL 5.7+ | 关系型数据库 |
| **通信协议** | TCP | 用户管理、数据查询 |
| | MQTT | 设备控制、实时数据上传 |
| | HTTP | 天气预报 |
| | JSON | 数据格式 |

---

## 🚀 快速开始

### 📋 前置要求

- **下位机开发**: Keil MDK / STM32CubeIDE
- **上位机开发**: Qt 5.9.9+
- **服务器开发**: GCC/G++ (C++11), CMake/Make
- **数据库**: MySQL 5.7+ 或 MariaDB 10+
- **操作系统**: macOS 10.15+ / Linux / Windows

### ⚡ 方法一：使用一键启动脚本（推荐）

#### 首次使用 - 初始化环境

```bash
# 克隆项目
git clone https://github.com/your_username/Embedded-Integrated-Project.git
cd Embedded-Integrated-Project

# 运行初始化脚本（自动安装依赖、编译、配置数据库）
./start.sh setup
```

#### 日常使用

```bash
# 启动所有服务
./start.sh start

# 查看服务状态
./start.sh status

# 运行功能测试
./test.sh

# 停止服务
./start.sh stop
```

**脚本功能**:
- ✅ 自动检查并安装依赖
- ✅ 编译 TCP 和 MQTT 服务器
- ✅ 初始化 MySQL 数据库
- ✅ 启动/停止/重启服务
- ✅ 查看服务运行状态
- ✅ 彩色输出，易于阅读

### ⚡ 方法二：手动启动

#### 1️⃣ 安装依赖（macOS）

```bash
# 安装 Homebrew（如果未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装所有依赖
brew install mysql boost jsoncpp paho-mqtt-c gcc
```

#### 2️⃣ 初始化数据库

```bash
# 启动 MySQL
brew services start mysql

# 创建数据库和表结构
mysql -u root -p < database_init.sql
```

#### 3️⃣ 编译并运行 TCP 服务器

```bash
cd BackgroundServer/TCP
make
./main
```

#### 4️⃣ 编译并运行 MQTT 服务器

```bash
cd BackgroundServer/MQTT
make
./main
```

#### 5️⃣ 运行 Qt 客户端

```bash
cd Qt/smart_home
qmake smart_home.pro
make
open smart_home.app
```

🎉 **完成！** 现在你可以：
- 使用 Qt 客户端注册用户
- 绑定设备（输入 ChipID）
- 查看实时传感器数据
- 远程控制 LED、风扇、蜂鸣器

---

## 📚 详细文档

### 🔰 新手指南

- [🍎 macOS 环境配置指南](SETUP_MACOS.md) - **从零开始搭建开发环境**
- [🏗️ 系统架构与数据流详解](ARCHITECTURE.md) - **深入理解系统设计**
- [📊 数据库设计文档](database_init.sql) - 完整的 SQL 脚本和注释
- [🔧 常见问题解答](#-常见问题)

### 🛠️ 实用脚本

| 脚本 | 功能 | 用法 |
|------|------|------|
| `start.sh` | 一键管理服务 | `./start.sh [start\|stop\|restart\|status\|setup]` |
| `test.sh` | 自动化功能测试 | `./test.sh` |

### 📖 分模块文档

#### 1. 下位机 (STM32F407)

**硬件组成**:
- 主控: STM32F407VET6 (ARM Cortex-M4, 168MHz)
- 通信: ESP8266-01S (WiFi + MQTT)
- 传感器:
  - DHT11: 温度 (0-50℃) / 湿度 (20-90%RH)
  - 光敏电阻: 光照强度 (ADC 采集)
- 执行器:
  - LED × 3 (GPIO 控制)
  - 直流风扇 (TIM PWM 调速)
  - 有源蜂鸣器 (GPIO 控制)
- 显示: 0.96" OLED (SSD1306, I2C 接口)
- 存储: AT24C02 (2Kbit EEPROM)

**软件功能**:
```
✅ WiFi 连接（AT 指令配置 ESP8266）
✅ MQTT 连接到云服务器
✅ 订阅主题: {ChipID} （接收控制指令）
✅ 发布主题: {ChipID} （上传传感器数据）
✅ 定时上传: 每 5 秒发送一次状态数据
✅ JSON 解析: 处理下传的控制命令
✅ OLED 显示: 实时显示传感器数值
✅ 按键菜单: 配置 WiFi、查看状态
✅ EEPROM: 保存 WiFi 配置（掉电不丢失）
```

**JSON 通信格式**:

*上传数据*:
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

*接收控制*:
```json
{
  "CMD": "control",
  "device": "fan",
  "value": 80
}
```

#### 2. 上位机 (Qt 5.9.9)

**核心功能**:

| 模块 | 功能描述 | 技术实现 |
|------|---------|---------|
| **用户系统** | 注册、登录、注销 | TCP + JSON |
| **设备管理** | 绑定/解绑设备、设备列表 | TCP + MySQL |
| **实时监控** | 温湿度曲线、光照图表 | QCustomPlot |
| **设备控制** | LED 开关、风扇调速、蜂鸣器 | MQTT |
| **语音识别** | 语音控制设备 | 百度 API + HTTP |
| **天气服务** | 城市选择、天气预报 | HTTP + JSON |
| **多媒体** | 在线音乐播放（扩展） | QMediaPlayer |

**项目结构**:
```
Qt/smart_home/
├── login.cpp/h        # 登录界面
├── regist.cpp/h       # 注册界面
├── func.cpp/h         # 主功能界面
├── dial.cpp/h         # 仪表盘控件
├── switchbutton.cpp/h # 开关按钮控件
├── resources/         # 图片、样式资源
└── smart_home.pro     # Qt 项目文件
```

#### 3. 后台服务器

##### TCP 服务器 (`BackgroundServer/TCP/`)

**技术**: Boost.Asio (跨平台异步 I/O)

**功能**:
- ✅ 用户注册/登录验证
- ✅ 设备绑定管理
- ✅ 实时数据查询
- ✅ 历史数据统计

**API 接口**:

```json
// 注册
{"CMD":"注册","ID":"user001","pass":"123456","name":"张三","email":"zhang@example.com"}

// 登录
{"CMD":"登录","ID":"user001","pass":"123456"}

// 绑定设备
{"CMD":"绑定","ID":"user001","ChipID":"511757085","name":"客厅设备"}

// 获取绑定列表
{"CMD":"获取绑定","ID":"user001"}

// 查询状态
{"CMD":"状态","ChipID":"511757085"}
```

**编译运行**:
```bash
cd BackgroundServer/TCP
make
./main
```

##### MQTT 服务器 (`BackgroundServer/MQTT/`)

**技术**: Paho MQTT C Client

**功能**:
- ✅ 订阅设备主题
- ✅ 接收传感器数据
- ✅ 解析 JSON 并写入 MySQL
- ✅ 心跳保活（10秒/次）

**数据处理流程**:
```
设备发布 → MQTT Broker → 服务器订阅 → JSON 解析 → MySQL 存储
```

**编译运行**:
```bash
cd BackgroundServer/MQTT
make
./main
```

---

## 🗄️ 数据库设计

### 表结构概览

| 表名 | 说明 | 主要字段 |
|------|------|---------|
| `user` | 用户信息 | ID, pass, name, email |
| `user_chip` | 设备绑定 | ID, ChipID, name |
| `chip` | 芯片注册 | ChipID, register_time |
| `device_info` | 设备传感器类型 | ChipID, device_name |
| `device_tem` | 温度数据 | ChipID, _value, _time |
| `device_hum` | 湿度数据 | ChipID, _value, _time |
| `device_light` | 光照数据 | ChipID, _value, _time |
| `device_led3` | LED 状态 | ChipID, _value, _time |
| `device_beep` | 蜂鸣器状态 | ChipID, _value, _time |
| `device_fan` | 风扇状态 | ChipID, _value, _time |

### 常用查询示例

```sql
-- 查询用户绑定的设备
SELECT uc.ChipID, uc.name 
FROM user_chip uc 
WHERE uc.ID = 'user001';

-- 查询最新温湿度
SELECT t._value as temperature, h._value as humidity,
       FROM_UNIXTIME(t._time) as time
FROM device_tem t
JOIN device_hum h ON t.ChipID = h.ChipID AND t._time = h._time
WHERE t.ChipID = '511757085'
ORDER BY t._time DESC LIMIT 1;

-- 查询最近 24 小时数据
SELECT FROM_UNIXTIME(_time) as time, _value as temperature
FROM device_tem
WHERE ChipID = '511757085'
  AND _time > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 24 HOUR))
ORDER BY _time ASC;
```

完整 SQL 脚本见: [`database_init.sql`](database_init.sql)

---

## 🛠️ 开发与部署

### 本地开发（macOS）

详见: [SETUP_MACOS.md](SETUP_MACOS.md)

### 云服务器部署（Linux）

以 Ubuntu 20.04 为例：

```bash
# 1. 安装依赖
sudo apt update
sudo apt install -y mysql-server libboost-dev libjsoncpp-dev libpaho-mqtt-dev build-essential

# 2. 配置 MySQL
sudo mysql_secure_installation
mysql -u root -p < database_init.sql

# 3. 编译服务器程序
cd BackgroundServer/TCP && make
cd ../MQTT && make

# 4. 后台运行
nohup ./TCP/main > tcp.log 2>&1 &
nohup ./MQTT/main > mqtt.log 2>&1 &

# 5. 设置开机自启（systemd）
sudo nano /etc/systemd/system/iot-tcp.service
```

创建 systemd 服务文件 `/etc/systemd/system/iot-tcp.service`:
```ini
[Unit]
Description=IoT TCP Server
After=network.target mysql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/iot/BackgroundServer/TCP
ExecStart=/opt/iot/BackgroundServer/TCP/main
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable iot-tcp
sudo systemctl start iot-tcp
sudo systemctl status iot-tcp
```

### STM32 固件烧录

1. **ESP8266 MQTT 固件**:
   - 下载 AI-Thinker MQTT 固件
   - 使用 ESP8266 Download Tool 烧录
   - 波特率: 115200

2. **STM32 程序**:
   - 使用 Keil MDK 编译
   - ST-Link 烧录
   - 或通过 USART ISP 模式

---

## ❓ 常见问题

### 1. 数据库连接失败

**问题**: `Can't connect to MySQL server`

**解决**:
```bash
# 检查 MySQL 是否运行
brew services list | grep mysql  # macOS
sudo systemctl status mysql      # Linux

# 检查防火墙
sudo ufw allow 3306/tcp          # Linux

# 测试连接
mysql -h 127.0.0.1 -u admin -p
```

### 2. 端口被占用

**问题**: `Address already in use`

**解决**:
```bash
# 查找占用进程
lsof -i :10000

# 终止进程
kill -9 <PID>
```

### 3. Qt 编译错误

**问题**: `QtMqtt module not found`

**解决**:
```bash
# 编译 QtMqtt 模块
cd Qt/qtmqtt-5.15
qmake qtmqtt.pro
make
sudo make install
```

### 4. ESP8266 无法连接 WiFi

**检查**:
- AT 指令测试: `AT+CWJAP?`
- 确认 WiFi 名称和密码正确
- 检查路由器是否允许新设备接入
- 重启 ESP8266: `AT+RST`

### 5. macOS Apple Silicon 兼容性

**问题**: 库架构不匹配

**解决**:
```bash
# 确保使用 ARM64 版本
arch -arm64 brew install boost

# 验证架构
file /opt/homebrew/lib/libboost_system.dylib
# 应显示: Mach-O 64-bit dynamically linked shared library arm64
```

更多问题请查看: [SETUP_MACOS.md](SETUP_MACOS.md#-常见问题)

---

## 📂 项目结构

```
Embedded-Integrated-Project/
├── BackgroundServer/          # 后台服务器
│   ├── TCP/                   # TCP 服务器 (Boost.Asio)
│   │   ├── main.cpp           # 主程序
│   │   ├── main.h             # 头文件
│   │   ├── Makefile           # 编译配置
│   │   ├── README.md          # 详细说明
│   │   └── MIGRATION_SUMMARY.md
│   └── MQTT/                  # MQTT 服务器 (Paho)
│       ├── main.cpp           # 主程序
│       └── Makefile           # 编译配置
├── Qt/                        # 上位机客户端
│   ├── smart_home/            # 主项目
│   │   ├── *.cpp/h            # 源代码
│   │   ├── smart_home.pro     # Qt 项目文件
│   │   └── resources/         # 资源文件
│   ├── qtmqtt-5.15/           # Qt MQTT 模块源码
│   └── switchbutton/          # 自定义控件
├── STM32F407/                 # 下位机固件
│   ├── USER/                  # 用户代码
│   │   └── main.c             # 主程序
│   ├── HARTDWARE/             # 硬件驱动
│   │   ├── ADC/               # ADC 驱动
│   │   ├── DHT11/             # 温湿度传感器
│   │   ├── OLED/              # OLED 显示
│   │   ├── UART/              # 串口通信
│   │   └── cJSON/             # JSON 解析库
│   └── SYS/                   # 系统文件
├── res/                       # 项目图片
├── database_init.sql          # 数据库初始化脚本 ⭐
├── SETUP_MACOS.md             # macOS 配置指南 ⭐
└── README.md                  # 本文件
```

---

## 🎯 扩展功能建议

- [ ] 添加微信小程序控制端
- [ ] 实现数据分析与异常告警
- [ ] 支持多语言界面
- [ ] 添加摄像头视频监控
- [ ] 实现智能家居场景联动
- [ ] 支持 Zigbee/Bluetooth Mesh

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

感谢以下开源项目：

- [Boost.Asio](https://www.boost.org/) - 跨平台网络库
- [Qt Framework](https://www.qt.io/) - GUI 框架
- [Paho MQTT](https://www.eclipse.org/paho/) - MQTT 客户端
- [cJSON](https://github.com/DaveGamble/cJSON) - C 语言 JSON 解析器
- [QCustomPlot](https://www.qcustomplot.com/) - Qt 绘图库

---

## 📞 联系方式

- 📧 Email: your_email@example.com
- 🌐 Blog: [你的博客链接]
- 💬 Issues: [GitHub Issues](https://github.com/your_username/Embedded-Integrated-Project/issues)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给一个 Star 支持一下！⭐**

Made with ❤️ by 括号侠

</div>
