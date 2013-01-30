#!/bin/bash

REMOTE_HOST='node.lwrandd.mobi'
GIT_DIR='/apps/lightweight_node'

echo "====source /root/.bash_profile===="
source /root/.bash_profile

## commands
touch_date="touch `date +'last_git_pull_node%Y%m%d_%k%M%S'`"
node_stop="/etc/init.d/node stop"
node_start="/etc/init.d/node start"
git_command="git pull; cd ; rm last_git_pull_node*"


## ssh test
echo "ssh start `date +'last_git_pull_node_%Y%m%d_%k%M%S'`"
echo "touch file remote host..."
ssh $REMOTE_HOST "$node_stop; cd $GIT_DIR; $git_command; $node_start; $touch_date "
echo "done"
