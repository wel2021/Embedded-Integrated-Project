-- ============================================
-- IoT 综合项目 - MySQL 数据库初始化脚本
-- ============================================
-- 适用于: MySQL 5.7+ / MariaDB 10+
-- 创建时间: 2026-05-29
-- 说明: 本脚本创建完整的数据库结构，包括用户管理、设备绑定、传感器数据存储
-- ============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS myproject 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

USE myproject;

-- ============================================
-- 1. 用户表 (user)
-- ============================================
-- 存储注册用户的基本信息
DROP TABLE IF EXISTS user;
CREATE TABLE user (
    ID VARCHAR(50) NOT NULL COMMENT '用户账号（唯一）',
    pass VARCHAR(100) NOT NULL COMMENT '密码',
    name VARCHAR(100) NOT NULL COMMENT '用户姓名',
    email VARCHAR(100) NOT NULL COMMENT '邮箱（唯一）',
    PRIMARY KEY (ID),
    UNIQUE KEY uk_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息表';

-- ============================================
-- 2. 用户设备绑定表 (user_chip)
-- ============================================
-- 存储用户与设备的绑定关系
DROP TABLE IF EXISTS user_chip;
CREATE TABLE user_chip (
    ID VARCHAR(50) NOT NULL COMMENT '用户账号',
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    name VARCHAR(100) DEFAULT NULL COMMENT '设备备注名称',
    PRIMARY KEY (ID, ChipID),
    KEY idx_chipid (ChipID),
    CONSTRAINT fk_user_chip_user FOREIGN KEY (ID) REFERENCES user(ID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户设备绑定表';

-- ============================================
-- 3. 芯片注册表 (chip)
-- ============================================
-- 记录所有注册过的设备芯片ID
DROP TABLE IF EXISTS chip;
CREATE TABLE chip (
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID（唯一）',
    register_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    PRIMARY KEY (ChipID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备芯片注册表';

-- ============================================
-- 4. 设备信息表 (device_info)
-- ============================================
-- 记录设备支持的传感器/执行器类型
DROP TABLE IF EXISTS device_info;
CREATE TABLE device_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    device_name VARCHAR(50) NOT NULL COMMENT '设备名称（tem/hum/light/beep/fan/led3）',
    UNIQUE KEY uk_chip_device (ChipID, device_name),
    KEY idx_chipid (ChipID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备传感器信息表';

-- ============================================
-- 5. 温度数据表 (device_tem)
-- ============================================
DROP TABLE IF EXISTS device_tem;
CREATE TABLE device_tem (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT '温度值（℃）',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='温度传感器数据表';

-- ============================================
-- 6. 湿度数据表 (device_hum)
-- ============================================
DROP TABLE IF EXISTS device_hum;
CREATE TABLE device_hum (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT '湿度值（%RH）',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='湿度传感器数据表';

-- ============================================
-- 7. 光照数据表 (device_light)
-- ============================================
DROP TABLE IF EXISTS device_light;
CREATE TABLE device_light (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT '光照强度值',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='光照传感器数据表';

-- ============================================
-- 8. LED3 状态表 (device_led3)
-- ============================================
DROP TABLE IF EXISTS device_led3;
CREATE TABLE device_led3 (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT 'LED状态（0=关闭，1=开启）',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='LED3状态记录表';

-- ============================================
-- 9. 蜂鸣器状态表 (device_beep)
-- ============================================
DROP TABLE IF EXISTS device_beep;
CREATE TABLE device_beep (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT '蜂鸣器状态（0=关闭，1=开启）',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='蜂鸣器状态记录表';

-- ============================================
-- 10. 风扇状态表 (device_fan)
-- ============================================
DROP TABLE IF EXISTS device_fan;
CREATE TABLE device_fan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ChipID VARCHAR(50) NOT NULL COMMENT '设备芯片ID',
    _value FLOAT NOT NULL COMMENT '风扇PWM值（0-100）',
    _time BIGINT NOT NULL COMMENT '时间戳（Unix timestamp）',
    KEY idx_chipid (ChipID),
    KEY idx_time (_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='风扇状态记录表';

-- ============================================
-- 插入测试数据（可选）
-- ============================================

-- 测试用户
INSERT INTO user (ID, pass, name, email) VALUES 
('10000', '123456', '测试用户', 'test@example.com'),
('admin', 'admin123', '管理员', 'admin@example.com')
ON DUPLICATE KEY UPDATE ID=ID;

-- 测试设备绑定
INSERT INTO user_chip (ID, ChipID, name) VALUES 
('10000', '511757085', '一号教室设备'),
('10000', 'Deng_511757085', '二号教室设备')
ON DUPLICATE KEY UPDATE ID=ID;

-- ============================================
-- 常用查询示例
-- ============================================

-- 查询某用户绑定的所有设备
-- SELECT uc.ChipID, uc.name FROM user_chip uc WHERE uc.ID = '10000';

-- 查询某设备最新的温度数据
-- SELECT _value, FROM_UNIXTIME(_time) as time FROM device_tem 
-- WHERE ChipID = '511757085' ORDER BY _time DESC LIMIT 1;

-- 查询某设备最近10条温湿度数据
-- SELECT t._value as temperature, h._value as humidity, 
--        FROM_UNIXTIME(t._time) as time 
-- FROM device_tem t 
-- JOIN device_hum h ON t.ChipID = h.ChipID AND t._time = h._time
-- WHERE t.ChipID = '511757085' 
-- ORDER BY t._time DESC LIMIT 10;

-- 删除超过30天的历史数据（定期清理）
-- DELETE FROM device_tem WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
-- DELETE FROM device_hum WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
-- DELETE FROM device_light WHERE _time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));

-- ============================================
-- 完成
-- ============================================
SELECT '数据库初始化完成！' AS message;
SHOW TABLES;
