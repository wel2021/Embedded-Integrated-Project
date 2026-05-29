#编译器版本C++11
FLAG  = -std=c++11
#需要jsoncpp库
FLAG += -ljsoncpp
#需要mysql库
FLAG += -lmysqlclient


all:
	g++ main.cpp ${FLAG} -I/opt/homebrew/include -L/opt/homebrew/lib -pthread -o main