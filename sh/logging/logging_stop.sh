#!/bin/bash

LANG=C

source ./logging_common.sh

### function
function kill_process() {
    if [ -f $WORK_DIR/$1.pid ]; then
        sudo kill `cat $WORK_DIR/$1.pid`
    fi
}

### Main
mkdir -p $OUT_DIR

echo `date "+%Y/%m/%d %H:%M:%S"` > $WORK_DIR/stop_time.txt

# kill processes
kill_process "sadc"
kill_process "top"
kill_process "jstat_openam"
kill_process "jstat_app"
kill_process "jstat_in"
kill_process "netstat"

# sar
if [ -f $WORK_DIR/system-data ]; then
    sudo sar -A -f $WORK_DIR/system-data > $WORK_DIR/system-data.log
fi

prev_day=`date -d '1 days ago' "+%d"`
now_day=`date "+%d"`
#sar -A -f /var/log/sa/sa$prev_day > $WORK_DIR/sar$prev_day.log
sar -A -f /var/log/sa/sa$now_day > $WORK_DIR/sar$now_day.log
#cat $WORK_DIR/sar$prev_day.log $WORK_DIR/sar$now_day.log > $WORK_DIR/sar.log
cat $WORK_DIR/sar$now_day.log > $WORK_DIR/sar.log

# clena up
cp $WORK_DIR/* $OUT_DIR
rm -rf $WORK_DIR

