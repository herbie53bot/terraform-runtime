#!/bin/bash
sudo find /iac -type d -exec chmod 777 {} \;
sudo chmod +x /iac/bin/run_terraform
/iac/bin/run_terraform plan
