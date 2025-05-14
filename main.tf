terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"
  
  # Uncomment this block if you want to use remote state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "game-store/terraform.tfstate"
  #   region         = "eu-north-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  # No hardcoded credentials - these will be provided by Jenkins environment
}

# Step 1: Create Security Group in Default VPC
resource "aws_security_group" "devops_sg" {
  name        = "game-store-security-group"
  description = "Allow SSH, HTTP, HTTPS, and application-specific ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (Not secure for production)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS access from anywhere
  }

  # Game Store Backend Port
  ingress {
    from_port   = 5274
    to_port     = 5274
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to backend port
  }

  # Game Store Frontend Port
  ingress {
    from_port   = 5003
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to frontend port
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "game-store-security-group"
  }
}

# Step 2: Create EC2 Instance with Security Group
resource "aws_instance" "game_store_instance" {
  ami           = var.ec2_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Attach Security Group by ID
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  # Install Docker, Docker Compose and deploy the game store application
  user_data = file("${path.module}/user_data.sh")

  # Add EBS volume for persistent data
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "GameStoreInstance"
  }
}

# Step 3: Create an Elastic IP for the instance
resource "aws_eip" "game_store_eip" {
  instance = aws_instance.game_store_instance.id
  domain   = "vpc"
  
  tags = {
    Name = "GameStoreEIP"
  }
}

output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.game_store_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the created EC2 instance"
  value       = aws_eip.game_store_eip.public_ip
}

output "application_urls" {
  description = "URLs to access the application"
  value = {
    frontend = "http://${aws_eip.game_store_eip.public_ip}:5003"
    backend  = "http://${aws_eip.game_store_eip.public_ip}:5274"
  }
}