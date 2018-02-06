#!/bin/sh
# chkconfig: 2345 99 00
# Startup script for Domino R5
#
# description: This script starts the Domino server in a screen session \
#              And ensures a proper shutdown before the system goes down.
#
# Author: Oystein Baarnes <dominolinux@baarnes.com>

DESC="Domino R5"
SrvAcc="notes"

DominoDir="/var/local/notesdata"
DominoSrv="/usr/local/lotus/bin/server"

TimeOutKill=300
TasksToKill="server replica router update stats logasio adminp sched calconn event pop3 imap maps ldap http smtp mtc amgr"

tok=0

. /etc/rc.d/init.d/functions

getpid() {
   pid=$(/sbin/pidof -s server)
}

getpid
case "$1" in

start)
   if [ ! "$pid" ]; then
     echo -n "Starting $DESC: "
     su - $SrvAcc -c "cd $DominoDir && screen -m -d -S Domino $DominoSrv"
     sleep 3
     getpid
     if [ "$pid" ]; then
       success
       touch /var/lock/subsys/domino
     else
       failure
     fi
     echo
   fi
;;
   
stop)
   TimeOutKill=$[TimeOutKill/2]
   echo -n "Shutting down $DESC: "
   if [ "$pid" ]; then
     cd $DominoDir
     /opt/lotus/notes/latest/linux/server -quit > /dev/null &

     # Let's wait for the Domino to terminate

     while [ "$pid" ] && [ "$tok" -lt "$TimeOutKill" ] ; do
       sleep 2; tok=$[tok+2]
       getpid
     done

     if  [ ! "$pid" ] ; then
       success
     else
       failure
       $0 kill
     fi
   else
     failure
   fi
   echo
;;

kill)
   echo -n "Killing $DESC: "

   for i in {1..2}; do kill -9 $(/sbin/pidof -s $TasksToKill) > /dev/null; sleep 1; done

   tmp=$(/sbin/pidof -s $TasksToKill)

   if [ "$tmp" = "" ]; then
     success
     rm -f /var/lock/subsys/domino
   else
     failure
   fi
   echo
;;

status)
      status server
;;
   
restart)
      if [ "$pid" ]; then
   	$0 stop
      fi
   	$0 start
;;

*)
      echo
      echo "Usage: domino {start|stop|kill|restart|status}"
      echo
      exit 1
;;

esac
