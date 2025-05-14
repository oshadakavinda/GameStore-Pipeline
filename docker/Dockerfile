FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    sshpass \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip install --no-cache-dir ansible ansible-core

# Create working directory
WORKDIR /ansible

# Default command
CMD ["ansible-playbook", "--version"]