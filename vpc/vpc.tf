# CREATING MAIN VPC---------------------------------------------------------------------------------------------
resource "aws_vpc" "apci_main_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-vpc"
  })
}

# CREATING INTERNET GATEWAY-------------------------------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.apci_main_vpc.id

   tags = {
    Name = "apci-igw"
  }
}

# CREATING FRONTEND SUBNETS-------------------------------------------------------------------------------------
resource "aws_subnet" "frontend_subnet_az_1a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.frontend_cidr_block[0]
  availability_zone = var.availability_zone[0]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-frontend-subnet-az-1a"
  })
}

resource "aws_subnet" "frontend_subnet_az_1b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.frontend_cidr_block[1]
  availability_zone = var.availability_zone[1]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-frontend-subnet-az-1b"
  })
}

# CREATING BACKEND SUBNETS--------------------------------------------------------------------------------------
resource "aws_subnet" "backend_subnet_az_1a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[0]
  availability_zone = var.availability_zone[0]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-backend-subnet-az-1a"
  })
}

resource "aws_subnet" "backend_subnet_az_1b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[1]
  availability_zone = var.availability_zone[1]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-backend-subnet-az-1b"
  })
}

resource "aws_subnet" "db_backend_subnet_az_1a" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[2]
  availability_zone = var.availability_zone[0]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-db-backend-subnet-az-1a"
  })
}

resource "aws_subnet" "db_backend_subnet_az_1b" {
  vpc_id     = aws_vpc.apci_main_vpc.id
  cidr_block = var.backend_cidr_block[3]
  availability_zone = var.availability_zone[1]

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-db-backend-subnet-az-1b"
  })
}

# CREATING PUBLIC ROUTE TABLE-----------------------------------------------------------------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

   tags = {
    Name = "apci-public-rt"
  }
}

# CREATING ROUTE TABLE ASSOCIATION FOR FRONTEND SUBNETS---------------------------------------------------------
resource "aws_route_table_association" "frontend_subnet_az_1a" {
  subnet_id      = aws_subnet.frontend_subnet_az_1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "frontend_subnet_az_1b" {
  subnet_id      = aws_subnet.frontend_subnet_az_1b.id
  route_table_id = aws_route_table.public_rt.id
}

# CREATING AN ELASTIC IP FOR NAT GATEWAY IN AVAILABILITY ZONE 1A------------------------------------------------
resource "aws_eip" "eip_az_1a" {
  domain = "vpc"

  tags = {
    Name = "apci-eip-az-1a"
  }
}

# CREATING A NAT GATEWAY FOR AVAILABILITY ZONE 1A---------------------------------------------------------------
resource "aws_nat_gateway" "nat_gw_az_1a" {
  allocation_id = aws_eip.eip_az_1a.id
  subnet_id     = aws_subnet.frontend_subnet_az_1a.id    # NAT Gateway is attached to a public subnet

  tags = {
    Name = "apci-nat-gw-az-1a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # Depends on the elastic IP and frontend subnet in availability zone 1a
  depends_on = [aws_eip.eip_az_1a, aws_subnet.frontend_subnet_az_1a]
}

# CREATING A PRIVATE ROUTE TABLE FOR AVAILABILITY ZONE 1A-------------------------------------------------------
resource "aws_route_table" "private_rt_az_1a" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_az_1a.id
  }

  tags = {
    Name = "apci-private-rt-az-1a"
  }
}

# CREATING ROUTE TABLE ASSOCIATION FOR BACKEND SUBNETS IN AVAILABILITY ZONE 1A----------------------------------
resource "aws_route_table_association" "backend_subnet_az_1a" {
  subnet_id      = aws_subnet.backend_subnet_az_1a.id
  route_table_id = aws_route_table.private_rt_az_1a.id
}

resource "aws_route_table_association" "db_backend_subnet_az_1a" {
  subnet_id      = aws_subnet.db_backend_subnet_az_1a.id
  route_table_id = aws_route_table.private_rt_az_1a.id
}

# CREATING AN ELASTIC IP FOR NAT GATEWAY IN AVAILABILITY ZONE 1B------------------------------------------------
resource "aws_eip" "eip_az_1b" {
  domain = "vpc"

  tags = {
    Name = "apci-eip-az-1b"
  }
}

# CREATING A NAT GATEWAY FOR AVAILABILITY ZONE 1B---------------------------------------------------------------
resource "aws_nat_gateway" "nat_gw_az_1b" {
  allocation_id = aws_eip.eip_az_1b.id
  subnet_id     = aws_subnet.frontend_subnet_az_1b.id   # NAT Gateway is attached to a public subnet

  tags = {
    Name = "apci-nat-gw-az-1b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # Depends on the elastic IP and frontend subnet in availability zone 1b
  depends_on = [aws_eip.eip_az_1b, aws_subnet.frontend_subnet_az_1b]
}

# CREATING A PRIVATE ROUTE TABLE FOR AVAILABILITY ZONE 1B-------------------------------------------------------
resource "aws_route_table" "private_rt_az_1b" {
  vpc_id = aws_vpc.apci_main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw_az_1b.id
  }

  tags = {
    Name = "apci-private-rt-az-1b"
  }
}

# CREATING ROUTE TABLE ASSOCIATION FOR BACKEND SUBNETS IN AVAILABILITY ZONE 1B----------------------------------
resource "aws_route_table_association" "backend_subnet_az_1b" {
  subnet_id      = aws_subnet.backend_subnet_az_1b.id
  route_table_id = aws_route_table.private_rt_az_1b.id
}

resource "aws_route_table_association" "db_backend_subnet_az_1b" {
  subnet_id      = aws_subnet.db_backend_subnet_az_1b.id
  route_table_id = aws_route_table.private_rt_az_1b.id
}