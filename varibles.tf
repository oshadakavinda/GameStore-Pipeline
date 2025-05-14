# Variables for AWS configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0989fb15ce71ba39e" # Amazon Linux 2 in eu-north-1 (replace with appropriate AMI for your region)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name to access EC2 instance"
  type        = string
  default     = "your-key-name" # Replace with your key pair name
}

variable "volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 20
}

# Ansible configuration variables
variable "ansible_enabled" {
  description = "Whether to enable Ansible provisioning"
  type        = bool
  default     = true
}

variable "setup_nginx" {
  description = "Whether to setup Nginx as a reverse proxy"
  type        = bool
  default     = true
}

variable "docker_compose_path" {
  description = "Path to the docker-compose.yml file"
  type        = string
  default     = "./docker-compose.yml"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file for Ansible"
  type        = string
  default     = "./your-key.pem" # Replace with your key path
}