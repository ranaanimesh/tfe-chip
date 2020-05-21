# AWS Region
variable "region" {
  default = "us-west-1"
}

# The AMI image to use (Debian 8)
variable "aws_amis" {
  default = {
    "us-west-1"      = "ami-06fcc1f0bc2c8943f"
  }
}

# Size of the instance
variable "instance_type" {
  default = "t2.small"
}

# SSH key to deploy
variable "key_name" {
  description = "Key pair to use"
  default     = "terraform_vm"
}

# Whitelist your IP for SSH access here
variable "ip_whitelist" {
  description = "Whitelisted IP for SSH access"
  default     = "0.0.0.0/0"
}
