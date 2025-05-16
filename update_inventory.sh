#!/bin/bash

# Navigate to the Terraform directory
cd terraform || { echo "❌ Failed to enter terraform directory"; exit 1; }

# Extract IP address from Terraform output
public_ip=$(terraform output -raw instance_public_ip 2>/dev/null)
public_ip=$(echo "$public_ip" | tr -d '[:space:]')

# Validate IP extraction
if [[ -z "$public_ip" ]]; then
  echo "❌ Error: Could not retrieve public IP from Terraform outputs."
  exit 1
fi

# Debug output to see what we're getting
echo "✅ Public IP extracted: ${public_ip}"

# Return to the root Jenkins workspace (assuming ansible/ is there)
cd ..

# Create Ansible inventory file
mkdir -p ansible
cat > ansible/inventory.ini << EOF
[game_store_servers]
${public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./gamestore.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "✅ Inventory file created successfully"
