#!/bin/sh

# 使用方法
# 
# auto_test start incremental end
#
# ex) auto_test 1000 1000 10000
#     1000件の同時接続から開始し、1000件ずつ増やし、10000件までテストする。
#

# 引数チェック
if [ $# -ne 3 ]; then
  echo "指定された引数は$#個です。" 1>&2
  echo "実行するには3個の引数が必要です。" 1>&2
  exit 1
fi

# 平均値取得用試行回数
count_for_average=3

# 結果を格納するディレクトリ
result_root_dir="/opt/result"
result_sub_dir=`date +%Y-%m-%d-%H%M%S`
result_dir=${result_root_dir}/${result_sub_dir}
mkdir ${result_dir}
mkdir ${result_dir}/logs
mkdir ${result_dir}/logs/ptn1
mkdir ${result_dir}/logs/ptn1/apache
mkdir ${result_dir}/logs/ptn1/jboss
mkdir ${result_dir}/logs/ptn1/oracle
mkdir ${result_dir}/logs/ptn4
mkdir ${result_dir}/logs/ptn4/nginx
mkdir ${result_dir}/logs/ptn4/node
mkdir ${result_dir}/logs/ptn4/oracle
mkdir ${result_dir}/logs/ptn5
mkdir ${result_dir}/logs/ptn5/nginx
mkdir ${result_dir}/logs/ptn5/node
mkdir ${result_dir}/logs/ptn5/mongo
summary_file=${result_root_dir}/${result_sub_dir}/summary


# 取得するログファイルへのフルパス
### Apache2.2
apache22_error_log="/opt/apache2.2/logs/error_log"
apache22_access_log="/opt/apache2.2/logs/access_log"
### JBoss
jboss_boot_log="/opt/jboss-as-7.1.1.Final/standalone/log/boot.log"
jboss_server_log="/opt/jboss-as-7.1.1.Final/standalone/log/server.log"
### Oracle
oracle_clsc_log="/u01/app/oracle/product/11.2.0/dbhome_1/log/oracle-server/client/clsc.log"
### Nginx

### Node.js

### MongoDB



################
# パターン1
################

##### 自動テストループ #####
start_connection=$1
incremental_connection=$2
end_connection=$3
now_connection=${start_connection}

while :
do
	echo "コネクション数：${now_connection}"

	mkdir ${result_dir}/logs/ptn1/apache/${now_connection}
	mkdir ${result_dir}/logs/ptn1/jboss/${now_connection}
	mkdir ${result_dir}/logs/ptn1/oracle/${now_connection}
	
	##### 平均値取得用ループ #####
	loop_counter=0
	while :
	do
		# ループ制御
		loop_counter=`expr ${loop_counter} + 1`
		if [ ${loop_counter} -gt ${count_for_average} ]; then
			break
		else
			mkdir ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn1/oracle/${now_connection}/${loop_counter}
		fi
		echo "${loop_counter}回目"
	
		# Apache2.2、JBoss、Oracleのログをローテーションして消去
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root apache22-server "hostname;\
			cp ${apache22_access_log} ${apache22_access_log}_${result_sub_dir}_${loop_counter};\
			cp ${apache22_error_log} ${apache22_error_log}_${result_sub_dir}_${loop_counter};\
			> ${apache22_access_log}; > ${apache22_error_log}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root jboss-server    "hostname;\
			cp ${jboss_boot_log} ${jboss_boot_log}_${result_sub_dir}_${loop_counter};\
			cp ${jboss_server_log} ${jboss_server_log}_${result_sub_dir}_${loop_counter};\
			> ${jboss_boot_log};      > ${jboss_server_log}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server   "hostname;\
			cp ${oracle_clsc_log} ${oracle_clsc_log}_${result_sub_dir}_${loop_counter};\
			> ${oracle_clsc_log}"
		
		# Apache2.2、JBoss、Oracleサーバを再起動
		#ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn1.rb stop
		#sleep 300
		#ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn1.rb start
		#sleep 300
		
		# sfatack_randツールを使ってパターン1に同時アクセスを試みる
		/git/lightweight_etc/tools/atack_tools/sfatack_rand ${now_connection} 3 10.0.0.14 /oracle
		
		# パターン1の各ミドルのログを取得する
		### Apache2.2
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@apache22-server:${apache22_error_log}  ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@apache22-server:${apache22_access_log} ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}/
		### JBoss
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@jboss-server:${jboss_boot_log}         ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@jboss-server:${jboss_server_log}       ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}/
		### Oracle
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${oracle_clsc_log}       ${result_dir}/logs/ptn1/oracle/${now_connection}/${loop_counter}/
		
		# パターン1の各サーバのリソースログを取得する
		### Apache2.2
		
		### JBoss
		
		### Oracle
	
	done

	# 平均値集計出力
	echo "同時接続数${now_connection}の時の200レスポンス数（平均）" >> ${summary_file}
	echo "apache：`expr \`cat ${result_dir}/logs/ptn1/apache/${now_connection}/*/access_log | grep 200 | wc -l\` / ${count_for_average}` / ${now_connection}" >> ${summary_file}

	# ループ制御
	now_connection=`expr ${now_connection} + ${incremental_connection}`
	if [ ${now_connection} -gt ${end_connection} ]; then
		break
	fi

done



