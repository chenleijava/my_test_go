#!/bin/bash
#配置集群端口起始
PORT=30000
#节点超时时间，用来failover的操作
TIMEOUT=2000
#集群节点数
NODES=6
#集群中的master节点带从节点数
REPLICAS=1
#集群ip地址(同一物理机 最好不要写回环地址)  注意 不要设置127.0.0.1  回环地址--- 跨网段访问
#物理机1
IP0=192.168.0.128
#物理机2
IP1=192.168.0.8


if [ -a config.sh ]
then
    source "config.sh"
fi

# Computed vars
ENDPORT=$((PORT+NODES))

#批量开启集群节点
if [ "$1" == "start" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "开始创建Reids实例 --- 端口: $PORT "
       ../redis-server --port $PORT --cluster-enabled yes --cluster-config-file nodes-${PORT}.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-${PORT}.aof --dbfilename dump-${PORT}.rdb --logfile ${PORT}.log --daemonize yes
    done
    exit 0
fi


#启动新节点(当前主机)
if [ "$1" == "start_node" ]
then
    ../redis-server --port $2 --cluster-enabled yes --cluster-config-file nodes-$2.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-$2.aof --dbfilename dump-$2.rdb --logfile $2.log --daemonize yes
    exit 0
fi

#创建集群
if [ "$1" == "create" ]
then
    HOSTS=""
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        HOSTS="$HOSTS $IP0:$PORT"
       # HOSTS="$HOSTS $IP1:$PORT"
    done
    echo "HOSTS:$HOSTS"
    ../redis-trib.rb create --replicas $REPLICAS $HOSTS
    exit 0
fi

#关闭集群节点
if [ "$1" == "stop" ]
then
    while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
       echo "关闭端口: $PORT + 实例... ..."
       ../redis-cli -p $PORT shutdown nosave
    done
    echo "关闭成功... ..."
    exit 0
fi

#监控当前注解节点
if [ "$1" == "watch" ]
then
    PORT=$((PORT+1))
    while [ 1 ]; do
        clear
        date
       ../redis-cli -p $PORT cluster nodes | head -30
        sleep 1
    done
    exit 0
fi

#查看日志
if [ "$1" == "tail" ]
then
    INSTANCE=$2
    PORT=$((PORT+INSTANCE))
    tail -f ${PORT}.log
    exit 0
fi

#跨网段加入,加入之前应该启动另一网段的redis集群实例 start_node
# 注意节点应该是在一个网段
# $2 新添加节点地址 192.168.0.1:8081
# $3 集群中的节点 192.168.0.195:8082
if [ "$1" == "join" ]
then
     echo "-------------------------------"
     echo "#跨网段加入,加入之前应该启动另一网段的redis集群实例 start_node
           # 注意节点应该是在一个网段
           # 参数1 新添加节点地址 192.168.0.1:8081
           # 参数2 集群中的节点 192.168.0.195:8082"
    ../redis-trib.rb add-node $2 $3
    exit 0
fi


#设置主从
if [ "$1" == "replicas" ]
then
  echo "-------------------------------"
  echo "添加主从前(不知道nodeid),应该知道master节点的nodeid,./create-cluster.sh show_nodes port,添加主从示例:127.0.0.1:31004> CLUSTER REPLICATE 2eb135bf03dbdbc57e704578b2833cc3fb860b6e
    其中 127.0.0.1:31004为讲添加到集群中的节点(你可以使用call 来调用);
	CLUSTER REPLICATE  --- redis命令;
	2eb135bf03dbdbc57e704578b2833cc3fb860b6e 为主库的集群ID"
     ../redis-cli -p $2
    exit 0
fi

#关闭所有订单 清理端口资源----- 新增集群节点无法被关闭掉
if [ "$1" == "clean" ]
then
#stop all
   while [ $((PORT < ENDPORT)) != "0" ]; do
        PORT=$((PORT+1))
        echo "关闭端口: $PORT ... ..."
       ../redis-cli -p $PORT shutdown nosave
    #remove data and config
    rm -rf $PORT.log
    rm -rf appendonly-$PORT.aof
    rm -rf dump-$PORT.rdb
    rm -rf nodes-$PORT.conf
    done
    #exit
        exit 0
fi

#删除从节点
#$2 ip:del_port 删除节点的地址
#$3 node_id  node 编号
#$4 del_port  用于删除文件(del_port)
if [ "$1" == "del_node" ]
then
  echo "del_node   -- 关闭节点 ./create-cluster.sh ip:del_port node_id del_port"
  ../redis-trib.rb del-node $2 $3

    echo "开始删除端口$4相关节点数据文件"
    rm -rf $4.log
    rm -rf appendonly-$4.aof
    rm -rf dump-$4.rdb
    rm -rf nodes-$4.conf

    echo "处理成功.... ..."
  exit 0
fi

# $2 新添加实例端口port  8081
# $3 新添加节点地址 127.0.0.1:8081
# $4 集群中的节点 127.0.0.1:8082
if [ "$1" == "add" ]
then
   echo "开启新的redis实例,端口:$2 ..."
  ../redis-server --port $2 --cluster-enabled yes --cluster-config-file nodes-$2.conf --cluster-node-timeout $TIMEOUT --appendonly yes --appendfilename appendonly-$2.aof --dbfilename dump-$2.rdb --logfile $2.log --daemonize yes
   echo "开启新的redis实例成功... ..."
   echo "添加到$3 到集群中节点$4... ..."
  ../redis-trib.rb add-node $3 $4
#  #添加设置主从
#  echo "设置主从$3 slave of $4"
#  ../redis-trib.rb create --replicas 1 $4
exit 0
fi

#test cluster
if [ "$1" == "test" ]
then
  ../redis-cli -c -p $2
  exit 0
fi



if [ "$1" == "show_nodes" ]
then
  echo "使用命令查看集群节点:cluster nodes"
  ../redis-cli -c -p $2
  exit 0
fi

#脚本操作使用文档
echo "---------------------------------------------------------------------------------------------------"
echo "Usage: $0 [start|start_node|create|stop|del_node|watch|tail|clean|add|test|replicas|join]"
echo "start       -- 启动redis实例"
echo "start_node  -- 开启新节点实例(可跨物理机--同网段)"
echo "del_node    -- 关闭从节点 ./create-cluster.sh ip:port(节点地址) node_id(节点编号)"
echo "create      -- 使用redis-trib创建集群"
echo "stop        -- 关闭redis集群实例"
echo "watch       -- 查看集群节点状态"
echo "add         -- 添加节点并设置主从 ./create-cluster.sh add 8081 127.0.0.1:8081 127.0.0.1:8082"
echo "tail <id>   -- 使用tail -f + port + ID查看redis实例信息"
echo "clean       -- 移除所有配置 ,日志相关文件"
echo "test        -- 测试集群客户端: use: ./create-cluster.sh test port"
echo "join        -- 添加跨网段的节点 #跨网段加入,加入之前应该启动另一网段的redis集群实例 start_node ,注意节点应该是在一个网段
                     参数1 新添加节点地址 192.168.0.1:8081
                     参数2 集群中的节点 192.168.0.195:8082"
echo "replicas    -- 设置主从,添加主从前(不知道nodeid),应该知道master节点的nodeid,./create-cluster.sh show_nodes port,
                  添加主从示例:127.0.0.1:31004> CLUSTER REPLICATE 2eb135bf03dbdbc57e704578b2833cc3fb860b6e
                     其中 127.0.0.1:31004为讲添加到集群中的节点(你可以使用call 来调用);
	                 CLUSTER REPLICATE  --- redis命令;
	                 2eb135bf03dbdbc57e704578b2833cc3fb860b6e 为主库的集群ID"

echo "show_nodes  -- 查看集群节点信息 port为集群中的任意节点端口: use: ./create-cluster.sh show_nodes port"
echo "---------------------------------------------------------------------------------------------------"
