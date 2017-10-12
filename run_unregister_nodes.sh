#!/bin/bash
sudo find /iac -type d -exec chmod 777 {} \;
sudo chmod +x /iac/bin/run_terraform

SSH_KEY="/home/herbie_bot/.ssh/deploy_key"
#get bastion ip
BASTION_IP=`terraform output -state=terraform/.terraform/terraform.tfstate bastion_ip`
echo "Bastion IP:" $BASTION_IP

#add bastion to known hosts
mkdir -p /home/herbie_bot/.ssh
ssh-keyscan -trsa $BASTION_IP > /home/herbie_bot/.ssh/known_hosts

#get private key from credstash
credstash -t ${DEPLOY_ENV}-secrets get deploy.ssh_key.private|base64 -d > /home/herbie_bot/.ssh/deploy_key
chmod 600 /home/herbie_bot/.ssh/deploy_key

ssh -i $SSH_KEY centos@$BASTION_IP "./unregister_nodes.sh"
