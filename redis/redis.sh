#!/bin/sh
#chkconfig: 345 86 14
#description: Startup and shutdown script for Redis
PROGNAME=./redis-server
DAEMON=$PROGNAME
CONFIG=./redis.conf
PIDFILE=./redis.pid
DESC="redis daemonize"
SCRIPTNAME=/etc/init.d/redisd
PORT=6379
PASSWORD=suwei
start()
{
         if test -x $DAEMON
         then
        echo -e "Starting $DESC: $PROGNAME"
                   if $DAEMON $CONFIG > /dev/null 2>&1 &
                   then
                            echo -e "OK"
                   else
                            echo -e "failed"
                   fi
         else
                   echo -e "Couldn't find Redis Server ($DAEMON)"
         fi
}

test_redis(){

    ./redis-cli -p $PORT -a $PASSWORD
}
 
stop()
{
         if test -e $PIDFILE
         then
                   echo -e "Stopping $DESC: $PROGNAME"
                   if kill  `cat $PIDFILE`
                   then
                            echo -e "OK"
                   else
                            echo -e "failed"
                   fi
         else
                   echo -e "No Redis Server ($DAEMON) running"
         fi
}
 
restart()
{
    echo -e "Restarting $DESC: $PROGNAME"
    stop
         start
}
 
list()
{
         ps aux | grep $PROGNAME
}



case $1 in
         start)
                   start
        ;;
         stop)
        stop
        ;;
         restart)
        restart
        ;;
         list)
        list
          ;;
         test_redis)
        test_redis
        ;;
         *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|list|test_redis}" >&2
        exit 1
        ;;
esac
exit 0
