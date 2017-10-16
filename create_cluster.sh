#!/bin/bash
#first make sure all directories are accessible
sudo find /iac -type d -exec chmod 777 {} \;
# make sure we can execute run_terraform
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

# wait for cloud-init to finish on the bastion without errors
echo "Waiting for Cloud-init to finish on the Bastion host. This takes about 6 minutes."
BOOT_FINISHED=`ssh -i $SSH_KEY centos@$BASTION_IP '[ -e /var/lib/cloud/instance/boot-finisheed ]'`
EXIT_STATUS=$?
while [ "$EXIT_STATUS" != "0" ]
do
  echo "waiting"
  sleep 15
  BOOT_FINISHED=`ssh -i $SSH_KEY centos@$BASTION_IP '[ -e /var/lib/cloud/instance/boot-finished ]'`
  EXIT_STATUS=$?
done

#check if no errors in result
OUTPUT=`ssh -i $SSH_KEY centos@$BASTION_IP 'sudo grep "\"errors\": \[\]" /var/lib/cloud/data/result.json'`
EXIT_STATUS=$?
if [ "$EXIT_STATUS" == "0" ];
then
  echo "Cloud-init finished without errors."
else
  echo "Cloud-init finished with error:" $OUTPUT
  exit 1
fi

# wait for ansible to start
echo "Waiting for Ansible to start logging. Should only take a minute."
ANSIBLE_LOG_EXISTS=`ssh -i $SSH_KEY centos@$BASTION_IP '[ -e /var/log/run_ansible.log ]'`
EXIT_STATUS=$?
while [ "$EXIT_STATUS" != "0" ]
do
  sleep 5
  ANSIBLE_LOG_EXISTS=`ssh -i $SSH_KEY centos@$BASTION_IP '[ -e /var/log/run_ansible.log ]'`
  EXIT_STATUS=$?
done
echo "Ansible started."

# wait for Ansible to finish on the Bastion without errors
echo "Waiting for Ansible base role playbook to finish on the Bastion host. This will take another 5 minutes."
ANSIBLE_DONE=`ssh -i $SSH_KEY centos@$BASTION_IP 'grep "^== End ========================" /var/log/run_ansible.log'`
EXIT_STATUS=$?
while [ "$EXIT_STATUS" != "0" ]
do
  echo "Waiting"
  sleep 15
  ANSIBLE_DONE=`ssh -i $SSH_KEY centos@$BASTION_IP 'grep "^== End ========================" /var/log/run_ansible.log'`
  EXIT_STATUS=$?
done
echo "Ansible run finished."

echo "Checking Ansible run results:"
ANSIBLE_SUCCESS=`ssh -i $SSH_KEY centos@$BASTION_IP 'grep -A1 PLAY\ RECAP /var/log/run_ansible.log' | grep ^localhost | grep -v failed=0`
EXIT_STATUS=$?
if [ "$EXIT_STATUS" == "1" ];
then
  echo "Ansible run successful"
else
  echo "There was an error, aborting."
  exit 1
fi
# check that the cm directory was created

#wait for cm dir to be created
echo "Checking if dir exists"
DIR_EXISTS=`ssh -i $SSH_KEY centos@$BASTION_IP '[ -d /home/centos/git/iuk/cm ]'`
EXIT_STATUS=$?
if [ "$EXIT_STATUS" == "0" ];
then
  echo "Directory exists."
else
  echo "Directory not found, aborting."
  exit 1
fi

echo "Checking cloud-init"
ssh -i $SSH_KEY centos@$BASTION_IP "./check-cloud-init.sh"
echo "Creating Openshift cluster"
ssh -i $SSH_KEY centos@$BASTION_IP "./create_openshift.sh"
