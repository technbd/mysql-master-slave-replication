#!/bin/bash
if ps aux | grep mysql > /dev/null
then
    pid=`ps aux | grep mysql | awk '{print $2}'`
    echo $pid
    kill -9 $pid
else
    echo "there is no Mysql running"
fi
    echo "Mysql Stopped"
