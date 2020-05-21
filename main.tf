data "aws_availability_zones" "available_us" {
  provider = aws.aws-west
  state    = "available"
}

module "aws_us_vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.aws_vpc_us_name
  cidr = var.aws_vpc_us_cidr_block

  # azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  azs  = [for zone in data.aws_availability_zones.available_us.names : zone]

  public_subnets = [for num in range(length(data.aws_availability_zones.available_us.names)) : cidrsubnet(var.aws_vpc_us_cidr_block, 5, (num + 1) * 8)]

  private_subnets = [for num in range(length(data.aws_availability_zones.available_us.names)) : cidrsubnet(var.aws_vpc_us_cidr_block, 5, ((num + 1) * 8) + 1)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.aws_vpc_us_name
  }

  providers = {
    aws = aws.aws-west
  }
}

data "aws_availability_zones" "available_eu" {
  provider =  aws.aws-eu
  state   = "available"
}

module "aws_eu_vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = var.aws_vpc_eu_name
  cidr = var.aws_vpc_eu_cidr_block

  # azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  azs  = [for zone in data.aws_availability_zones.available_eu.names : zone]

  public_subnets = [for num in range(length(data.aws_availability_zones.available_eu.names)) : cidrsubnet(var.aws_vpc_eu_cidr_block, 5, (num + 1) * 8)]

  private_subnets = [for num in range(length(data.aws_availability_zones.available_eu.names)) : cidrsubnet(var.aws_vpc_eu_cidr_block, 5, ((num + 1) * 8) + 1)]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.aws_vpc_eu_name
  }

  providers = {
    aws = aws.aws-eu
  }
}

resource "aws_vpc_peering_connection" "peer" {
  provider      = aws.aws-west
  vpc_id        = module.aws_us_vpc.vpc_id
  peer_vpc_id   = module.aws_eu_vpc.vpc_id
  peer_region   = "eu-central-1"
  auto_accept   = false

  tags = {
    Name = "vpc-us-west-1 to vpc-eu-central-1 VPC peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.aws-eu
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}

resource "aws_default_security_group" "us-west-vpc" {
  provider = aws.aws-west
  vpc_id   = module.aws_us_vpc.vpc_id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_security_group" "eu-central-vpc" {
  provider = aws.aws-eu
  vpc_id   = module.aws_eu_vpc.vpc_id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route" "us-vpc" {
  provider                  = aws.aws-west
  count                     = length(module.aws_eu_vpc.public_subnets_cidr_blocks)
  route_table_id            = module.aws_us_vpc.public_route_table_ids[0]
  destination_cidr_block    = module.aws_eu_vpc.public_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "eu-vpc" {
  provider                  = aws.aws-eu
  count                     = length(module.aws_us_vpc.public_subnets_cidr_blocks)
  route_table_id            = module.aws_eu_vpc.public_route_table_ids[0]
  destination_cidr_block    = module.aws_us_vpc.public_subnets_cidr_blocks[count.index]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
