locals{
  azslist = data.aws_availability_zones.eu-azs.names   
  azslistnum = [1,2,3]
  azslistwest = data.aws_availability_zones.west-azs.names
  azslistnumwest = [1,2]
}
provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "us-west-1"
  region = "us-west-1"
}


data "aws_availability_zones" "eu-azs" {
  provider = aws.eu-central-1
  state = "available"
}

module "eu-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eu-vpc"
  cidr = "10.0.0.0/16"

# Grab entire set of names if needed from data source
  #azs             = [data.aws_availability_zones.eu-azs.names[0], data.aws_availability_zones.eu-azs.names[1], data.aws_availability_zones.eu-azs.names[2]]
  azs             = local.azslist

# Use cidrsubnet function with for_each to create the right number of subnets
  #public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  #public_subnets  = cidrsubnets("10.0.0.0/16", 2, 2, 2, 2)  
  
  public_subnets  =  [
      for num in local.azslistnum:
      cidrsubnet("10.0.0.0/16", 2, num)
    ] 

    #public_subnets  = cidrsubnet("10.0.0.0/16", 2, )  

  providers = {
    aws = aws.eu-central-1
  }
}


##########################################################################

data "aws_availability_zones" "west-azs" {
  provider = aws.us-west-1
  state = "available"
}

module "west-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "west-vpc"
  cidr = "10.1.0.0/16"

# Grab entire set of names if needed from data source
  azs             = local.azslistwest

# Use cidrsubnet function with for_each to create the right number of subnets
  #public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  public_subnets  =  [
      for num in local.azslistnumwest:
      cidrsubnet("10.1.0.0/16", 2, num)
    ] 


  providers = {
    aws = aws.us-west-1
  }
}

##########################################################################


resource "aws_vpc_peering_connection" "peer" {
  provider      = aws.eu-central-1
  vpc_id        = module.eu-vpc.vpc_id
  peer_vpc_id   = module.west-vpc.vpc_id
  peer_region   = "us-west-1"
  auto_accept   = false
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.us-west-1
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}

##########################################################################

resource "aws_default_security_group" "eu-vpc" {
  provider = aws.eu-central-1
  vpc_id   = module.eu-vpc.vpc_id

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

##########################################################################

resource "aws_default_security_group" "west-vpc" {
  provider = aws.us-west-1
  vpc_id   = module.west-vpc.vpc_id

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

##########################################################################

resource "aws_route" "eu-vpc" {
  provider                  = aws.eu-central-1
# Need to create a route for every combination of route_table_id on module.eu-vpc.public_route_table_ids with every cidr_block on module.west-vpc.public_cidr_blocks. Look into setproduct function. Using setproduct, element, and length, this can be done dynamically
  count                     = 1
  route_table_id            = module.eu-vpc.public_route_table_ids[0]
  destination_cidr_block    = module.west-vpc.public_subnets_cidr_blocks[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

##########################################################################

resource "aws_route" "west-vpc" {
  provider                  = aws.us-west-1
# Need to create a route for every combination of route_table_id on module.west-vpc.public_route_table_ids with every cidr_block on module.eu-vpc.public_cidr_blocks. Look into setproduct function. Using setproduct, element, and length, this can be done dynamically
  count                     = 1
  route_table_id            = module.west-vpc.public_route_table_ids[0]
  destination_cidr_block    = module.eu-vpc.public_subnets_cidr_blocks[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}






#####################################################################


# to be removed
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_s3_bucket" "b" {
  provider = aws.us-east-1
  bucket = "my-tf-test-bucket-terraform-chip"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}


#####################################################################
