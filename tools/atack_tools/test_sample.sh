#!/bin/sh

# 使用方法
# 
# test_sample start incremental end
#
# ex) test_sample 1000 1000 10000
#     1000件の同時接続から開始し、1000件ずつ増やし、10000件までテストする。（サンプルでテストする）
#

# 引数チェック
if [ $# -ne 3 ]; then
  echo "指定された引数は$#個です。" 1>&2
  echo "実行するには3個の引数が必要です。" 1>&2
  exit 1
fi

# 平均値取得用試行回数
count_for_average=1
# 実施フラグ
ptn1_flg=1
ptn4_flg=1
ptn5_flg=1

# 結果を格納するディレクトリ
result_root_dir="/opt/sample_result"
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
oracle_alert_log="/u01/app/oracle/diag/rdbms/xe/XE/trace/alert_XE.log"
### Nginx
nginx_access_log="/opt/nginx/logs/access.log"
nginx_error_log="/opt/nginx/logs/error.log"
### Node.js
node_log="/var/log/node.log"
### MongoDB
mongo_log="/var/log/mongod.log"

# リソース取得シェル用コマンド
logging_command_start="cd /git/lightweight_etc/sh/logging/; /etc/init.d/sysstat start; sh logging_start.sh < /dev/null > /dev/null 2> /dev/null"
logging_command_stop="cd /git/lightweight_etc/sh/logging/; sh logging_stop.sh; /etc/init.d/sysstat stop"
logging_command_result="/git/lightweight_etc/sh/logging/perf/latest/*"


################
# パターン1
################

if [ ${ptn1_flg} -eq 1 ]; then

echo "パターン1開始" >> ${summary_file}

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
			cp ${oracle_alert_log} ${oracle_alert_log}_${result_sub_dir}_${loop_counter};\
			> ${oracle_clsc_log};     > ${oracle_alert_log}"
		
		# Apache2.2、JBoss、Oracleサーバを再起動
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn1.rb stop
		sleep 180
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn1.rb start
		sleep 180

		# リソースログ取得用シェルを起動する
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root apache22-server "${logging_command_start}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root jboss-server    "${logging_command_start}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server   "${logging_command_start}"
		
		# sfatack_randツールを使ってパターン1に同時アクセスを試みる
		/git/lightweight_etc/tools/atack_tools/sfatack ${now_connection} 3 10.0.0.14 /sample/sample.jsp
		
		# リソースログ取得用シェルを終了する
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root apache22-server "${logging_command_stop}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root jboss-server    "${logging_command_stop}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server   "${logging_command_stop}"
		
		# パターン1の各ミドルのログを取得する
		### Apache2.2
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@apache22-server:${apache22_error_log}  ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@apache22-server:${apache22_access_log} ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}/
		### JBoss
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@jboss-server:${jboss_boot_log}         ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@jboss-server:${jboss_server_log}       ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}/
		### Oracle
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${oracle_clsc_log}       ${result_dir}/logs/ptn1/oracle/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${oracle_alert_log}       ${result_dir}/logs/ptn1/oracle/${now_connection}/${loop_counter}/
		
		# パターン1の各サーバのリソースログを取得する
		### Apache2.2
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@apache22-server:${logging_command_result}  ${result_dir}/logs/ptn1/apache/${now_connection}/${loop_counter}/
		### JBoss
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@jboss-server:${logging_command_result}     ${result_dir}/logs/ptn1/jboss/${now_connection}/${loop_counter}/
		### Oracle
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${logging_command_result}    ${result_dir}/logs/ptn1/oracle/${now_connection}/${loop_counter}/
	
	done

	# 平均値集計出力
	echo "同時接続数${now_connection}の時の200レスポンス数（平均）" >> ${summary_file}
	echo "apache：`expr \`cat ${result_dir}/logs/ptn1/apache/${now_connection}/*/access_log | grep ' 200 ' | wc -l\` / ${count_for_average}` / ${now_connection}" >> ${summary_file}

	# ループ制御
	now_connection=`expr ${now_connection} + ${incremental_connection}`
	if [ ${now_connection} -gt ${end_connection} ]; then
		break
	fi

done

fi

################
# パターン4
################

if [ ${ptn4_flg} -eq 1 ]; then

echo "パターン4開始" >> ${summary_file}

##### 自動テストループ #####
start_connection=$1
incremental_connection=$2
end_connection=$3
now_connection=${start_connection}

while :
do
	echo "コネクション数：${now_connection}"

	mkdir ${result_dir}/logs/ptn4/nginx/${now_connection}
	mkdir ${result_dir}/logs/ptn4/node/${now_connection}
	mkdir ${result_dir}/logs/ptn4/oracle/${now_connection}
	
	##### 平均値取得用ループ #####
	loop_counter=0
	while :
	do
		# ループ制御
		loop_counter=`expr ${loop_counter} + 1`
		if [ ${loop_counter} -gt ${count_for_average} ]; then
			break
		else
			mkdir ${result_dir}/logs/ptn4/nginx/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn4/node/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn4/oracle/${now_connection}/${loop_counter}
		fi
		echo "${loop_counter}回目"
	
		# Nginx、Node.js、MongoDBのログをローテーションして消去
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server "hostname;\
			cp ${nginx_access_log} ${nginx_access_log}_${result_sub_dir}_${loop_counter};\
			cp ${nginx_error_log} ${nginx_error_log}_${result_sub_dir}_${loop_counter};\
			> ${nginx_access_log}; > ${nginx_error_log}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server    "hostname;\
			cp ${node_log} ${node_log}_${result_sub_dir}_${loop_counter};\
			> ${node_log}"
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server   "hostname;\
                        cp ${oracle_clsc_log} ${oracle_clsc_log}_${result_sub_dir}_${loop_counter};\
			cp ${oracle_alert_log} ${oracle_alert_log}_${result_sub_dir}_${loop_counter};\
			> ${oracle_clsc_log};     > ${oracle_alert_log}"
		
		# Nginx、Node.js、Oracleサーバを再起動
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn4.rb stop
		sleep 180
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn4.rb start
		sleep 180
		
		# リソースログ取得用シェルを起動する
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server  "${logging_command_start}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server "${logging_command_start}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server "${logging_command_start}"

		# sfatack_randツールを使ってパターン4に同時アクセスを試みる
		/git/lightweight_etc/tools/atack_tools/sfatack ${now_connection} 3 10.0.0.16 /oracle
		
		# リソースログ取得用シェルを終了する
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server  "${logging_command_stop}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server "${logging_command_stop}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root oracle-server "${logging_command_stop}"
		
		# パターン4の各ミドルのログを取得する
		### Nginx
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${nginx_error_log}   ${result_dir}/logs/ptn4/nginx/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${nginx_access_log}  ${result_dir}/logs/ptn4/nginx/${now_connection}/${loop_counter}/
		### Node.js
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nodejs-server:${node_log}         ${result_dir}/logs/ptn4/node/${now_connection}/${loop_counter}/
		### Oracle
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${oracle_clsc_log}  ${result_dir}/logs/ptn4/oracle/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${oracle_alert_log} ${result_dir}/logs/ptn4/oracle/${now_connection}/${loop_counter}/
		
		# パターン4の各サーバのリソースログを取得する
		### Nginx
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${logging_command_result}   ${result_dir}/logs/ptn4/nginx/${now_connection}/${loop_counter}/
		### Node.js
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nodejs-server:${logging_command_result}  ${result_dir}/logs/ptn4/node/${now_connection}/${loop_counter}/
		### Oracl
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@oracle-server:${logging_command_result}  ${result_dir}/logs/ptn4/oracle/${now_connection}/${loop_counter}/
	
	done

	# 平均値集計出力
	echo "同時接続数${now_connection}の時の200レスポンス数（平均）" >> ${summary_file}
	echo "nginx：`expr \`cat ${result_dir}/logs/ptn4/nginx/${now_connection}/*/access.log | grep ' 200 ' | wc -l\` / ${count_for_average}` / ${now_connection}" >> ${summary_file}

	# ループ制御
	now_connection=`expr ${now_connection} + ${incremental_connection}`
	if [ ${now_connection} -gt ${end_connection} ]; then
		break
	fi

done

fi

################
# パターン5
################

if [ ${ptn5_flg} -eq 1 ]; then

echo "パターン5開始" >> ${summary_file}

##### 自動テストループ #####
start_connection=$1
incremental_connection=$2
end_connection=$3
now_connection=${start_connection}

while :
do
	echo "コネクション数：${now_connection}"

	mkdir ${result_dir}/logs/ptn5/nginx/${now_connection}
	mkdir ${result_dir}/logs/ptn5/node/${now_connection}
	mkdir ${result_dir}/logs/ptn5/mongo/${now_connection}
	
	##### 平均値取得用ループ #####
	loop_counter=0
	while :
	do
		# ループ制御
		loop_counter=`expr ${loop_counter} + 1`
		if [ ${loop_counter} -gt ${count_for_average} ]; then
			break
		else
			mkdir ${result_dir}/logs/ptn5/nginx/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn5/node/${now_connection}/${loop_counter}
			mkdir ${result_dir}/logs/ptn5/mongo/${now_connection}/${loop_counter}
		fi
		echo "${loop_counter}回目"
	
		# Nginx、Node.js、MongoDBのログをローテーションして消去
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server "hostname;\
			cp ${nginx_access_log} ${nginx_access_log}_${result_sub_dir}_${loop_counter};\
			cp ${nginx_error_log} ${nginx_error_log}_${result_sub_dir}_${loop_counter};\
			> ${nginx_access_log}; > ${nginx_error_log}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server    "hostname;\
			cp ${node_log} ${node_log}_${result_sub_dir}_${loop_counter};\
			> ${node_log}"
		ssh -n -i ~/.ssh/lwRandDkey.pem -l root mongo-server   "hostname;\
			cp ${mongo_log} ${mongo_log}_${result_sub_dir}_${loop_counter};\
			> ${mongo_log}"
		
		# Nginx、Node.js、MongoDBサーバを再起動
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn5.rb stop
		sleep 180
		ruby /git/lightweight_etc/aws-sh/ec2ctl_ptn5.rb start
		sleep 180

                # リソースログ取得用シェルを起動する
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server  "${logging_command_start}"
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server "${logging_command_start}"
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root mongo-server  "${logging_command_start}"
		
		# sfatack_randツールを使ってパターン5に同時アクセスを試みる
		/git/lightweight_etc/tools/atack_tools/sfatack ${now_connection} 3 10.0.0.16 /mongo

                # リソースログ取得用シェルを終了する
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root nginx-server  "${logging_command_stop}"
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root nodejs-server "${logging_command_stop}"
                ssh -n -i ~/.ssh/lwRandDkey.pem -l root mongo-server  "${logging_command_stop}"
		
		# パターン5の各ミドルのログを取得する
		### Nginx
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${nginx_error_log}  ${result_dir}/logs/ptn5/nginx/${now_connection}/${loop_counter}/
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${nginx_access_log} ${result_dir}/logs/ptn5/nginx/${now_connection}/${loop_counter}/
		### Node.js
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nodejs-server:${node_log}        ${result_dir}/logs/ptn5/node/${now_connection}/${loop_counter}/
		### MongoDB
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@mongo-server:${mongo_log}        ${result_dir}/logs/ptn5/mongo/${now_connection}/${loop_counter}/
		
		# パターン5の各サーバのリソースログを取得する
		### Nginx
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nginx-server:${logging_command_result}   ${result_dir}/logs/ptn5/nginx/${now_connection}/${loop_counter}/
		### Node.js
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@nodejs-server:${logging_command_result}  ${result_dir}/logs/ptn5/node/${now_connection}/${loop_counter}/
		### MongoDB
		scp -P 22 -i ~/.ssh/lwRandDkey.pem root@mongo-server:${logging_command_result}   ${result_dir}/logs/ptn5/mongo/${now_connection}/${loop_counter}/
	
	done

	# 平均値集計出力
	echo "同時接続数${now_connection}の時の200レスポンス数（平均）" >> ${summary_file}
	echo "nginx：`expr \`cat ${result_dir}/logs/ptn5/nginx/${now_connection}/*/access.log | grep ' 200 ' | wc -l\` / ${count_for_average}` / ${now_connection}" >> ${summary_file}

	# ループ制御
	now_connection=`expr ${now_connection} + ${incremental_connection}`
	if [ ${now_connection} -gt ${end_connection} ]; then
		break
	fi

done

fi

