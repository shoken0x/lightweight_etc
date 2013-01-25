#!/bin/sh

PATTERN1_URL=http://apache22.lwrandd.mobi/sample/sample.jsp
PATTERN1_WORD=11.2.0.2.0

PATTERN2_URL=http://apache24.lwrandd.mobi/oracle
PATTERN2_WORD=fujisaki

PATTERN3_URL=http://apache24.lwrandd.mobi/mongo
PATTERN3_WORD=fujisaki

PATTERN4_URL=http://nginx.lwrandd.mobi/oracle
PATTERN4_WORD=fujisaki

PATTERN5_URL=http://nginx.lwrandd.mobi/mongo
PATTERN5_WORD=fujisaki


if [ $# -ne 0 ]; then
  echo "エラー：引数は必要ありません。" 1>&2
  exit 1
fi

echo -n "パターン1 : "
if [ `./patternX_check.sh $PATTERN1_URL $PATTERN1_WORD` ] ; then
  echo -e "[ \033[0;32mOK\033[0;39m ]"
else
  echo -e "[ \033[0;31mNG\033[0;39m ]"
fi

echo -n "パターン2 : "
if [ `./patternX_check.sh $PATTERN2_URL $PATTERN2_WORD` ] ; then
  echo -e "[ \033[0;32mOK\033[0;39m ]"
else
  echo -e "[ \033[0;31mNG\033[0;39m ]"
fi

echo -n "パターン3 : "
if [ `./patternX_check.sh $PATTERN3_URL $PATTERN3_WORD` ] ; then
  echo -e "[ \033[0;32mOK\033[0;39m ]"
else
  echo -e "[ \033[0;31mNG\033[0;39m ]"
fi

echo -n "パターン4 : "
if [ `./patternX_check.sh $PATTERN4_URL $PATTERN4_WORD` ] ; then
  echo -e "[ \033[0;32mOK\033[0;39m ]"
else
  echo -e "[ \033[0;31mNG\033[0;39m ]"
fi

echo -n "パターン5 : "
if [ `./patternX_check.sh $PATTERN5_URL $PATTERN5_WORD` ] ; then
  echo -e "[ \033[0;32mOK\033[0;39m ]"
else
  echo -e "[ \033[0;31mNG\033[0;39m ]"
fi
