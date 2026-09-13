
## VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

## Private Subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

## Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

## Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


## Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-public-rt"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

## Route for Internet Access to Public Subnets
resource "aws_route_table_association" "public_internet_access" {
    route_table_id         = aws_route_table.public.id
    subnet_id              = aws_subnet.public[count.index].id
    count                  = length(var.public_subnet_cidrs)
}


## for private subnets, we need a NAT Gateway to allow outbound internet access
## Elastic IP for NAT Gateway
## Route Table for Private Subnets

## Create NAT Gateway
resource "aws_nat_gateway" "main" {
    count = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-gateway-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

## route table for private subnets
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.cluster_name}-private-rt-${count.index + 1}"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
}

## Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    route_table_id = aws_route_table.private[count.index].id
    subnet_id      = aws_subnet.private[count.index].id
}