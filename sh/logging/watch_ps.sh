process=httpd
out=watch_ps_$process
while [ 1 ]; do
    echo "F   UID   PID  PPID PRI  NI    VSZ   RSS WCHAN  STAT TTY        TIME COMMAND" >> $out
    ps alx | head -1 && ps alx | grep $process | grep -v [g]rep>> $out # サーバによってファイル名を変更する
    sleep 1
done
