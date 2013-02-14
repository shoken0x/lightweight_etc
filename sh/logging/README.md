## Usage

### start

```
sh logging_start.sh
```

### stop
```
sh logging_stop.sh
```


### output
```
[root@local logging]# ll perf/2013.02.14_14.35.04/
合計 328
-rw-r--r-- 1 root root   4630  2月 14 14:35 netstat.log
-rw-r--r-- 1 root root      6  2月 14 14:35 netstat.pid
-rw-r--r-- 1 root root      6  2月 14 14:35 sadc.pid
-rw-r--r-- 1 root root  31277  2月 14 14:35 sar.log
-rw-r--r-- 1 root root  31277  2月 14 14:35 sar14.log
-rw-r--r-- 1 root root     20  2月 14 14:35 start_time.txt
-rw-r--r-- 1 root root     20  2月 14 14:35 stop_time.txt
-rw-r--r-- 1 root root  17360  2月 14 14:35 system-data
-rw-r--r-- 1 root root  20024  2月 14 14:35 system-data.log
-rw-r--r-- 1 root root 195919  2月 14 14:35 top.log
-rw-r--r-- 1 root root      6  2月 14 14:35 top.pid

```

## install sysstat

```
yum install sysstat  
/etc/init.d/sysstat start  
```

## Graph
windows only

```
ruby netstat_summary.rb netstat.log
```
