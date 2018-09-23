# vpc module
# Creation of :
# - VPC 
# - Public subnets (depending on lenght of a variable)
# - Private subnets (depending on lenght of a variable)
# - Internet gateway
# - Nat gateway
# - Security groups

# Creation of the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Creation of public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.public_subnets_cidr)}"
  cidr_block              = "${element(var.public_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Creation of private subnets
resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(var.private_subnets_cidr)}"
  cidr_block              = "${element(var.private_subnets_cidr, count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# EIP for the NAT Gateway 
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.igw"]
}

# NAT Gateway (Internet access for the private subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = ["aws_internet_gateway.igw"]

  tags {
    Name        = "${var.environment}-${element(var.availability_zones, count.index)}-nat"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Routing table for private subnet
resource "aws_route_table" "private_route" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Routing table for public subnet
resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.environment}-public-route-table"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route.id}"
}

resource "aws_route_table_association" "private" {
  count           = "${length(var.private_subnets_cidr)}"
  subnet_id       = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id  = "${aws_route_table.private_route.id}"
}

# Defining the default rules 
resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public_route.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private_route.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

# Security Group
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"
  depends_on  = ["aws_vpc.vpc"]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags {
    Environment = "${var.environment}"
    Terraform   = true
  }
}
