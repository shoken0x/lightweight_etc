#!/bin/bash


source ./logging_common.sh

#### check
if [ -d $WORK_DIR ]; then
    echo "logging already started ..."
    exit 
fi

### function
function exec_jstat() {
    tomcat_pid=`sudo /usr/java/default/bin/jps -v | grep tomcat-6.0_$1 | awk '{print $1}'`
    if [ "$tomcat_pid" != "" ]; then 
        sudo $JAVA_HOME/bin/jstat -gc ${tomcat_pid}  ${INTERVAL_SEC}000 > $WORK_DIR/jstat_$1.log &
        PID=$!
        echo $! > $WORK_DIR/jstat_$1.pid
        echo "jstat($1) pid : $tomcat_pid"
    fi
}

### Main
mkdir -p $WORK_DIR

echo `date "+%Y/%m/%d %H:%M:%S"` > $WORK_DIR/start_time.txt

# sysstat
sudo /usr/lib64/sa/sadc $INTERVAL_SEC $WORK_DIR/system-data &
PID=$!
echo $PID > $WORK_DIR/sadc.pid
echo "sysstat pid : $PID"

# top
top -b -d $INTERVAL_SEC > $WORK_DIR/top.log &
PID=$!
echo $PID > $WORK_DIR/top.pid
echo "top pid : $PID"

# netstat
(
    while [ 1 ]; do
        echo "----- " `date "+%Y/%m/%d %H:%M:%S"` >> $WORK_DIR/netstat.log
        netstat -anp | egrep ':80 |:8080 |:27017 |:1521' >> $WORK_DIR/netstat.log 
        sleep $INTERVAL_SEC
    done
) &
PID=$!
echo $PID > $WORK_DIR/netstat.pid
echo "netstat pid : $PID"

# jstat(OpenAM)
# exec_jstat "openam"

# jstat(App)
# exec_jstat "app"

# jstat(In)
# exec_jstat "in"

# tail log file
cnt=0
for file in ${LOG_FILE[*]}; do

    if [ -r $file ]; then
        echo "tailed : $file"
        filename=`expr $file : "/.*/\(.*\)"`
        tail -n 0 -f --pid=`cat $WORK_DIR/sadc.pid` $file > $WORK_DIR/${cnt}_$filename &
        cnt=$((cnt+1))
    fi

done
