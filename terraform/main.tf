resource "aws_security_group" "devops_sg" {
  name        = "game-store-security-group"
  description = "Allow SSH, HTTP, HTTPS, and application-specific ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5274
    to_port     = 5274
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5003
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "game-store-security-group"
  }
}

resource "aws_instance" "game_store_instance" {
  ami                    = var.ec2_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  user_data              = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "GameStoreInstance"
  }
}

resource "aws_eip" "game_store_eip" {
  instance = aws_instance.game_store_instance.id
  domain   = "vpc"

  tags = {
    Name = "GameStoreEIP"
  }
}
