#Create VPC in us-east-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc"
  }

}


#Create IGW in us-east-1
resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

#Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# Create subnet DMZ in us-east-1
resource "aws_subnet" "SUB_DMZ_0" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
}

# Create subnet PRIV_0 in us-east-1
resource "aws_subnet" "SUB_PRIV_0" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
}


#Create route table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}


#Create NAT GW
resource "aws_nat_gateway" "nat-gw" {
  provider      = aws.region-master
  allocation_id = aws_eip.eipfornat.id
  subnet_id     = aws_subnet.SUB_DMZ_0.id

  tags = {
    Name = "gw NAT"
  }
}

# Create Elastic IP for NAT GW

resource "aws_eip" "eipfornat" {
  provider = aws.region-master
  #instance = aws_instance.web.id
  vpc = true
}

#Create route internal only with NatGW
resource "aws_route_table" "internal_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT-internal"
  }
}

#Assign RT_internal to SUB_PRIV_0
resource "aws_route_table_association" "a" {
  provider       = aws.region-master
  subnet_id      = aws_subnet.SUB_PRIV_0.id
  route_table_id = aws_route_table.internal_route.id
}


resource "aws_security_group" "my-sg-out-to-jh" {
  provider    = aws.region-master
  name        = "my-sg-out-to-jh"
  description = "Allow TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/%s", data.external.whatismyip.result["internet_ip"], 32)]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Here should be IP of JH
resource "aws_security_group" "my-sg-in-from-jh" {
  provider    = aws.region-master
  name        = "my-sg"
  description = "Allow TCP/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.aws_instance_JH.private_ip}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



data "external" "whatismyip" {
  program = ["/bin/bash", "${path.module}/whatismyip.sh"]
}
