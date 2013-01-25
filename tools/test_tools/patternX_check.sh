#!/bin/sh

if [ $# -ne 2 ]; then
  echo "エラー：実行するには2個の引数が必要です。" 1>&2
  echo "書き方）patternX_check.sh TARGET_URL TARGET_WORD" 1>&2
  echo "使用例）patternX_check.sh http://apache22.lwrandd.mobi/sample/sample.jsp Oracle" 1>&2
  exit 1
fi

if [ `curl -m 3 -s "$1" | grep "$2" | wc -l` != 0 ] ; then
  echo 'OK'
fi
