#!/bin/bash
echo "[$AWS_PROFILE]" > /home/herbie_bot/.aws/credentials
sudo find /iac -type d -exec chmod 777 {} \;
sudo chmod +x /iac/bin/run_terraform

/iac/bin/run_terraform refresh

SSH_KEY="/home/herbie_bot/.ssh/deploy_key"
#get bastion ip
BASTION_IP=`/iac/bin/run_terraform output bastion_ip`
echo "Bastion IP:" $BASTION_IP

#add bastion to known hosts
mkdir -p /home/herbie_bot/.ssh
ssh-keyscan -trsa $BASTION_IP > /home/herbie_bot/.ssh/known_hosts

#unset AWS_PROFILE because credstash can't handle it
unset AWS_PROFILE

#get private key from credstash
credstash -t ${DEPLOY_ENV}-secrets get deploy.ssh_key.private|base64 -d > /home/herbie_bot/.ssh/deploy_key
chmod 600 /home/herbie_bot/.ssh/deploy_key

ssh -i $SSH_KEY centos@$BASTION_IP "./unregister_nodes.sh"
