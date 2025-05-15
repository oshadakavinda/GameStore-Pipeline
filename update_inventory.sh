#!/bin/bash

# Navigate to the Terraform directory
cd terraform || exit

# Get the public IP of the server from Terraform
SERVER_IP=$(terraform output -raw instance_public_ip)

# Navigate back to Ansible directory
cd ../ansible || exit

# Clear the previous content of the inventory
echo "" > inventory.ini

# Update the Ansible inventory file
echo "[ec2]" > inventory.ini
echo "ec2-instance ansible_host=$SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=gamestore.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> inventory.ini