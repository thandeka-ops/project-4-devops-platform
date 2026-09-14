resource "aws_ecr_repository" "project4_app" {
  name                 = "project4-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "project4" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "project4-vpc"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "project4" {
  vpc_id = aws_vpc.project4.id

  tags = {
    Name        = "project4-igw"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.project4.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "project4-public-${var.availability_zones[count.index]}"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.project4.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "project4-private-${var.availability_zones[count.index]}"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project4.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project4.id
  }

  tags = {
    Name        = "project4-public-rt"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "project4-nat-eip"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_nat_gateway" "project4" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "project4-nat"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.project4]
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.project4.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.project4.id
  }

  tags = {
    Name        = "project4-private-rt"
    Project     = "Project4"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}