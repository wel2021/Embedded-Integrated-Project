/* Boost.Asio - 跨平台网络库 */
#include <boost/asio.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/enable_shared_from_this.hpp>
#include <boost/array.hpp>
/* std */ 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <iostream>
#include <memory>
using namespace std;
/*-------- Mysql ------------*/
#include <mysql/mysql.h>
/*-------- JSON -------------*/
#include <json/json.h>
using namespace Json;

using boost::asio::ip::tcp;

/************* 网络编程服务器作为案例 *********************************************************************
 * 使用Boost.Asio实现跨平台TCP服务器
 * 1.监听 sid 服务器有用户连接
 * 2.监听 cid 客户端有数据可读
 * 
 * Boost.Asio会自动在底层调用:
 * - macOS: kqueue
 * - Linux: epoll
 * - Windows: IOCP
 * ***************************************************************************************************/
#define MAXSIZE 1024
#include "main.h"

// 前向声明业务逻辑函数
void tcp_ret_state(int cid, Value &json, MYSQL &mysql);
void tcp_get_bind(int cid, Value &json, MYSQL &mysql);
void tcp_bind(int cid, Value &json, MYSQL &mysql);
void tcp_login(int cid, Value &json, MYSQL &mysql);
void tcp_regist(int cid, Value &json, MYSQL &mysql);
bool connectDB(MYSQL &mysql);

// 前向声明
void handle_client_message(tcp::socket& socket, char* buf, int len, MYSQL& mysql);

// 会话类：负责处理单个客户端的连接与数据收发
class Session : public boost::enable_shared_from_this<Session> {
public:
    typedef boost::shared_ptr<Session> pointer;
    
    static pointer create(boost::asio::io_context& io_context, MYSQL& mysql) {
        return pointer(new Session(io_context, mysql));
    }
    
    tcp::socket& socket() {
        return socket_;
    }
    
    void start() {
        do_read();
    }
    
private:
    tcp::socket socket_;
    MYSQL& mysql_;
    enum { max_length = 200 };
    char data_[max_length];
    
    Session(boost::asio::io_context& io_context, MYSQL& mysql)
        : socket_(io_context), mysql_(mysql) {
        memset(data_, 0, sizeof(data_));
    }
    
    void do_read() {
        auto self(shared_from_this());
        socket_.async_read_some(
            boost::asio::buffer(data_, max_length),
            [this, self](boost::system::error_code ec, std::size_t length) {
                if (!ec) {
                    // 读取成功，处理消息
                    handle_client_message(socket_, data_, length, mysql_);
                    // 继续读取下一条消息
                    do_read();
                } else {
                    // 连接断开
                    printf("有内鬼,终止交易\n");
                }
            });
    }
};

// 服务器类：负责监听端口和接受连接
class TcpServer {
public:
    TcpServer(boost::asio::io_context& io_context, short port, MYSQL& mysql)
        : acceptor_(io_context, tcp::endpoint(tcp::v4(), port)), mysql_(mysql), io_context_(io_context) {
        do_accept();
    }
    
private:
    tcp::acceptor acceptor_;
    MYSQL& mysql_;
    boost::asio::io_context& io_context_;
    
    void do_accept() {
        acceptor_.async_accept(
            [this](boost::system::error_code ec, tcp::socket socket) {
                if (!ec) {
                    printf("有cid连接\n");
                    // 创建会话并启动
                    auto session = Session::create(io_context_, mysql_);
                    // 将接受的socket移动到session
                    new (&session->socket()) tcp::socket(std::move(socket));
                    session->start();
                }
                // 继续接受下一个连接
                do_accept();
            });
    }
};

// 处理客户端消息的辅助函数
void handle_client_message(tcp::socket& socket, char* buf, int len, MYSQL& mysql) {
    if (len <= 0) return;
    
    /*----------- 处理客户端cid的内容 ---------------*/
    /*--------------- MQTT数据处理:JSON ------------------*/
    Reader json_reader;
    Value json;  //JSON对象
    
    json_reader.parse(buf, json);    //解析
    if(json.isObject() == false) return;
    
    /*--------------------- 客户端发送JSON格式:注册信息 -------------------------*/
    if(json.isMember("CMD") == true)
    {
        // 获取socket的文件描述符用于发送响应
        int cid = socket.native_handle();
        
        if(json["CMD"].asString() == "注册")
            tcp_regist(cid, json, mysql);
        else if(json["CMD"].asString() == "登录")
            tcp_login(cid, json, mysql);
        else if(json["CMD"].asString() == "绑定")
            tcp_bind(cid, json, mysql);
        else if(json["CMD"].asString() == "获取绑定")
            tcp_get_bind(cid, json, mysql);
        else if(json["CMD"].asString() == "状态")
            tcp_ret_state(cid, json, mysql);
    }
}

int main()
{
    /*----------- 连接数据库 ---------------------------------------------------------*/
    MYSQL mysql;
    if (connectDB(mysql) == true){
        cout << "连接mysql数据库成功" << endl;
    }
    else{
        cout << "连接mysql数据库失败" << endl;
        return -1;
    }
    mysql_select_db(&mysql,"myproject");//切换数据库
    
    try {
        // 1. 创建 io_context (核心事件循环，替代 epoll_create)
        boost::asio::io_context io_context;
        
        // 2. 启动服务器，监听 10000 端口
        TcpServer server(io_context, 10000, mysql);
        cout << "Server running on port 10000..." << endl;
        
        // 3. 运行事件循环（在 macOS 底层自动调用 kqueue，Linux 调用 epoll）
        io_context.run();
    }
    catch (std::exception& e) {
        cerr << "Exception: " << e.what() << "\n";
        return -1;
    }
    
    return 0;
}

void tcp_ret_state(int cid,Value &json,MYSQL &mysql){
    cout<<"更新状态"<<endl;
    char sql[200];
    int ret = -1;
    /*----- 根据sql执行结果返回JSON结果 --------*/
    Value json_ret;
    json_ret["CMD"] = "状态更新";
    MYSQL_ROW row;	// 记录数组
    float temp;
    /*----- 解析内容，并写入到数据库user中 -----*/
    const char *ChipID   = json["ChipID"].asCString();
    /*----- 查询数据库 -----------------------*/
    sprintf(sql,"select _value from device_hum where ChipID='%s' ORDER BY _time DESC LIMIT 2;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    MYSQL_RES *RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp += stol(row[0]);
        }
        temp = temp/2;
        json_ret["hum"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }
    temp=0;
    sprintf(sql,"select _value from device_tem where ChipID='%s' ORDER BY _time DESC LIMIT 2;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp += stol(row[0]);
        }
        temp = temp/2;
        json_ret["tem"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    temp=0;
    sprintf(sql,"select _value from device_light where ChipID='%s' ORDER BY _time DESC LIMIT 2;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp += stol(row[0]);
        }
        temp = temp/2;
        json_ret["light"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    sprintf(sql,"select _value from device_led3 where ChipID='%s' ORDER BY _time DESC LIMIT 1;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp = stol(row[0]);
        }
        json_ret["led3"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    sprintf(sql,"select _value from device_beep where ChipID='%s' ORDER BY _time DESC LIMIT 1;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp = stol(row[0]);
        }
        json_ret["beep"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    sprintf(sql,"select _value from device_fan where ChipID='%s' ORDER BY _time DESC LIMIT 1;",ChipID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    RES = mysql_store_result(&mysql); //获取结果集
    if(RES)
    {
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            temp = stol(row[0]);
        }
        json_ret["fan"]=temp;   //加入到数组中
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    /*----- 将其发送 --------------------------*/
    string json_str = json_ret.toStyledString();
    cout<<"状态更新发送客户端数据:"<<json_str<<endl;
    send(cid,json_str.data(),strlen(json_str.data()),0);
}

// {
//     "CMD":"获取绑定",			   				 /*命令字*/
//     "ID":"10000",								/*账号*/
// }
// {
//     "CMD":"绑定列表",		 /*命令字*/
//     "list":[
//         {
//          "芯片ID":"1516DC4611515D6516"
//          "备注":"一号教室"
//         },
//         {
//          "芯片ID":"1516DC461111111111"
//          "备注":"二号教室"
//         },
//     ]
// }
void tcp_get_bind(int cid,Value &json,MYSQL &mysql)    //获取绑定芯片
{
    char sql[200];
    int ret = -1;
    /*----- 解析内容，并写入到数据库user中 -----*/
    const char *ID   = json["ID"].asCString();
    /*----- 查询数据库 -----------------------*/
    sprintf(sql,"select ChipID,name from user_chip where ID='%s';",ID);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    MYSQL_RES *RES = mysql_store_result(&mysql); //获取结果集

    /*----- 根据sql执行结果返回JSON结果 --------*/
    Value json_ret;
    json_ret["CMD"] = "绑定列表";
    MYSQL_ROW row;	// 记录数组
    if(RES)
    {
        Value json_device;
        while((row = mysql_fetch_row(RES)) != NULL)
        {
            json_device["芯片ID"] = row[0];
            json_device["备注"] = row[1];
            json_ret["list"].append(json_device);   //加入到数组中
        }
        /*---- 记得释放结果集 -----*/
        mysql_free_result(RES);
    }

    /*----- 将其发送 --------------------------*/
    string json_str = json_ret.toStyledString();
    send(cid,json_str.data(),strlen(json_str.data()),0);
}


// {
//     "CMD":"绑定",			   					   /*命令字*/
//     "ID":"10000",								/*账号*/
//     "ChipID":"1516DC4611515D6516",			    /*芯片ID*/
//     "name":"备注"								  /*备注*/
// }
void tcp_bind(int cid,Value &json,MYSQL &mysql)
{
    char sql[200];
    int ret = -1;
    /*----- 解析内容，并写入到数据库user中 -----*/
    const char *ID   = json["ID"].asCString();
    const char *ChipID = json["ChipID"].asCString();
    const char *name = json["name"].asCString();
    /*----- 插入数据库 -----------------------*/
    sprintf(sql,"insert into user_chip values('%s','%s','%s');",ID,ChipID,name);
    /*----- 执行sql语句 -----------------------*/
    cout << "执行SQL:" << sql << endl;
    ret = mysql_real_query(&mysql,sql,strlen(sql));
    if(ret != 0)
    {
        cout << "错误原因:" << mysql_error(&mysql) << endl;
        /*--- 出现两种原因: 1.芯片ID不存在   2.重复绑定 ----*/
    }
    /*----- 根据sql执行结果返回JSON结果 --------*/
    Value json_ret;
    json_ret["CMD"] = "绑定结果";
    json_ret["State"] = (ret == 0 ? true : false);
    /*----- 将其发送 --------------------------*/
    string json_str = json_ret.toStyledString();
    send(cid,json_str.data(),strlen(json_str.data()),0);
}


// {
//     "CMD":"登录",		/*命令字*/
//     "ID":"10000",		/*账号*/
//     "pass":"123456",		/*密码*/
// }
void tcp_login(int cid,Value &json,MYSQL &mysql)
{
    char sql[200];
    int ret = -1;
    /*----- 解析内容，并写入到数据库user中 -----*/
    const char *ID   = json["ID"].asCString();
    const char *pass = json["pass"].asCString();
    /*----- 查询数据库 -----------------------*/
    sprintf(sql,"select * from user where ID='%s' and pass='%s';",ID,pass);
    /*----- 执行sql -------------------------*/
    mysql_real_query(&mysql,sql,strlen(sql));   //执行
    MYSQL_RES *RES = mysql_store_result(&mysql); //获取结果集
    int row = mysql_num_rows(RES); //获取结果行数
    /*---- 记得释放结果集 -----*/
    mysql_free_result(RES);

    /*----- 根据sql执行结果返回JSON结果 --------*/
    Value json_ret;
    json_ret["CMD"] = "登录结果";
    json_ret["State"] = (row == 1 ? true : false);
    /*----- 将其发送 --------------------------*/
    string json_str = json_ret.toStyledString();
    send(cid,json_str.data(),strlen(json_str.data()),0);
}


void tcp_regist(int cid,Value &json,MYSQL &mysql)
{
    char sql[200];
    int ret = -1;
    /*----- 解析内容，并写入到数据库user中 -----*/
    const char *ID   = json["ID"].asCString();
    const char *pass = json["pass"].asCString();
    const char *name = json["name"].asCString();
    const char *email = json["email"].asCString();
    /*----- 写入数据库 ------------------------*/
    sprintf(sql,"insert into user values('%s','%s','%s','%s');",ID,pass,name,email);
    
    /*----- 执行sql语句 -----------------------*/
    cout << "执行SQL:" << sql << endl;

    ret = mysql_real_query(&mysql,sql,strlen(sql));
    if(ret != 0)
    {
        cout << "错误原因:" << mysql_error(&mysql) << endl;
        /*--- 出现两种原因: 1.账号重复   2.邮箱重复 ----*/
    }
    /*----- 根据sql执行结果返回JSON结果 --------*/
    Value json_ret;
    json_ret["CMD"] = "注册结果";
    json_ret["State"] = (ret == 0 ? true : false);
    /*----- 将其发送 --------------------------*/
    string json_str = json_ret.toStyledString();
    send(cid,json_str.data(),strlen(json_str.data()),0);
}



/*****************************************************
 * 1.开启tcp服务器,等待客户端连接
 * 2.JSON格式处理客户端消息
 * 3.与Mysql数据库操作
 * **************************************************/
bool connectDB(MYSQL &mysql)
{
    // 初始化文件句柄
    mysql_init(&mysql);
    // 设置字符编码
    mysql_options(&mysql, MYSQL_SET_CHARSET_NAME, "utf8");
    // 连接数据库
    MYSQL *ret = mysql_real_connect(&mysql, "139.199.212.89", "admin", "admin123", NULL, 3306, NULL, 0);
    if (ret == NULL){
        cout << "数据库连接失败！原因：" << mysql_error(&mysql) << endl;
        return false;
    }
    else
        cout << "数据库连接成功！" << endl;
    return true;
}