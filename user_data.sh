#!/bin/bash

# This script is now minimal as most configuration will be handled by Ansible
# It just ensures the system is updated and SSH is available for Ansible

# Update the system
yum update -y || apt-get update -y

# Ensure SSH server is running for Ansible connectivity
if [ -f /etc/redhat-release ]; then
    # For Amazon Linux/CentOS/RHEL
    systemctl enable sshd
    systemctl start sshd
else
    # For Ubuntu/Debian
    systemctl enable ssh
    systemctl start ssh
fi

# Optional: Create a marker file to indicate this instance is ready for Ansible
echo "$(date) - EC2 instance initialized and ready for Ansible provisioning" > /var/log/terraform-ansible-ready.log