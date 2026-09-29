# ==============================================================================
# Terraform Configuration for AWS EC2 CI/CD Host Environment
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group for Jenkins and FastAPI
resource "aws_security_group" "cicd_sg" {
  name        = "cicd-fastapi-sg"
  description = "Allow inbound SSH, Jenkins (8080), and FastAPI (8001)"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    description = "Jenkins Web Interface"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    description = "FastAPI App Port"
    from_port   = 8001
    to_port     = 8001
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
    Name        = "cicd-fastapi-sg"
    Environment = "DevOps"
  }
}

# EC2 Instance for Docker & Jenkins
resource "aws_instance" "cicd_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.cicd_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y git curl wget ca-certificates python3 python3-pip python3-venv docker.io
              systemctl enable --now docker
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name        = "Jenkins-Docker-Host"
    Environment = "DevOps"
  }
}
