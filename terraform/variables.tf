variable "aws_region" {
  description = "AWS deployment region"
  type        = "string"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance size (t3.medium recommended for Jenkins + Docker)"
  type        = "string"
  default     = "t3.medium"
}

variable "ami_id" {
  description = "Ubuntu 24.04 / 22.04 LTS AMI ID"
  type        = "string"
  default     = "ami-0c7217cdde317cfec"
}

variable "key_pair_name" {
  description = "SSH key pair name"
  type        = "string"
  default     = "devops-key"
}

variable "allowed_ip" {
  description = "CIDR block permitted to access Jenkins and SSH"
  type        = "string"
  default     = "0.0.0.0/0"
}
