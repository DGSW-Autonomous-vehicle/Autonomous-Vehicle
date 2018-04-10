#! /bin/sh
### BEGIN INIT INFO
# Provides:          #PROVIDES
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: weavedConnectd remote access proxy initscript
# Description:       for more info go to http://weaved.com
### END INIT INFO

WEAVED_PORT=
DAEMON=weavedConnectd
WEAVED_DIR=/etc/weaved
BIN_DIR=/usr/bin
NOTIFIER=notify.sh
INIT_DIR=/etc/init.d
PID_DIR=/var/run
BIN_PATH=$BIN_DIR/$DAEMON
PIDPATH=$PID_DIR/$WEAVED_PORT.pid
LOG_FILE=/dev/null


# Generic functions or can be replaced by LSB functions
# Defined here for distributions that don't define
# log_daemon_msg
log_daemon_msg () 
{
    echo $@
}

# log_end_msg
log_end_msg () 
{
    retval=$1
    if [ $retval -eq 0 ]; then
        echo "."
    else
        echo " failed!"
    fi
    return $retval
}


#
# Function pidrunning, returns pid of running process or 0 if not running
#
pidrunning()
{
    pid=$1
    #ps=`ps ax`
    tpid=`ps 'ax' | awk '$1 == '$pid'{ print $1 }'`
#ps ax | awk '$1 == 3407 { print $1 }'
    # make sure we got reply
    if [ -z "$tpid" ]
    then
        tpid=0
    fi
    echo "$tpid"
}

do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    if [ ! -e $PIDPATH ]                                       
    then    
        logger "[$WEAVEDPORT] shutdown called, No Running Pidfile, Nothing Done, exiting"
        echo -n " No Running Pidfile [FAIL]"
        return 1;
    fi 
    #
    # kill with pid, first get pid from file
    #
    tmp=`cat $PIDPATH`

    # kill pid if running
    if [ "$tmp" = `pidrunning $tmp` ]
    then
        kill $tmp
        sleep 1
    else
        logger "[$WEAVEDPORT] shutdown called, pidfile found but process not running, exiting"
        echo -n " Pidfile Found but not running [FAIL]"
        # Delete Pidfile
        rm $PIDPATH 
        return 2;        
    fi   
    #wait for pid to die 5 seconds
    count=0                   # Initialise a counter
    while [ $count -lt 5 ]  
    do
        if [ "$tmp" != `pidrunning $tmp`  ] 
        then
            echo -n " [OK]";
            break;
        fi
        # not dead yet
        count=`expr $count + 1`  # Increment the counter
        echo -n " still running"
        sleep 1
    done
                  
    if [ "$tmp" = `pidrunning $tmp`  ]                                           
    then
        # hard kill
        echo -n " hk [OK]";
        kill -9 $tmp
    fi 
                        
    # remove PID file      
    rm $PIDPATH

    return 0;
}

do_start()
{
    RETVAL=2
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    if [ -f ${PIDPATH} ] ; then
        echo -n "already running "
        RETVAL=1
    else
        $BIN_PATH -f $WEAVED_DIR/services/$WEAVED_PORT.conf -d $PIDPATH > $LOG_FILE
        sleep 1
        if [ -f ${PIDPATH} ] ; then
             RETVAL=0
            echo -n " [OK]"
        else
            echo -n " [FAIL]"
        fi
    fi
}


case "$1" in
    start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$WEAVED_PORT"
    
        do_start

        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
    ;;

    stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$WEAVED_PORT"
        
        do_stop
        case "$?" in
            0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
            2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
    ;;

    restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        [ "$VERBOSE" != no ] && log_daemon_msg "Restarting $DESC" "$WEAVED_PORT"
        [ "$VERBOSE" != no ] && log_daemon_msg "  Stopping $DESC" "$WEAVED_PORT"
        do_stop
        [ "$VERBOSE" != no ] && log_end_msg "$?"
        case "$?" in
            0|1)
            [ "$VERBOSE" != no ] && log_daemon_msg "  Starting $DESC" "$WEAVED_PORT"
            do_start
            case "$?" in
                0) log_end_msg 0 ;;
                1) log_end_msg 1 ;; # Old process is still running
                *) log_end_msg 1 ;; # Failed to start
            esac
            ;;

        *)
            # Failed to stop
            log_end_msg 1
        ;;
        esac
    ;;
    
    *)
        #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
    ;;
esac

