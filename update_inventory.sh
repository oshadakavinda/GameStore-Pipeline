
#!/bin/bash

# Extract IP address from Terraform output
public_ip=$(terraform output -raw instance_public_ip)
public_ip=$(echo "$public_ip" | tr -d '[:space:]')

# Debug output to see what we're getting
echo "Public IP extracted: ${public_ip}"

# Create Ansible inventory file
mkdir -p ansible
cat > ansible/inventory.ini << EOF
[game_store_servers]
${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./gamestore.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory file created successfully"