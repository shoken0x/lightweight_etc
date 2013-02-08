#!/bin/bash

REMOTE_HOST='lwrandd.mobi'
GIT_DIR='/home/bitnami/git/lightweight_web'

echo "====source /root/.bash_profile===="
source /root/.bash_profile


## ssh test
echo "ssh start `date +'last_git_pull_%Y%m%d_%k%M%S'`"
echo "touch file remote host..."
ssh $REMOTE_HOST "cd $GIT_DIR; git pull; cd ; rm last_git_pull_*; touch `date +'last_git_pull_%Y%m%d_%k%M%S'`"
echo "done"
