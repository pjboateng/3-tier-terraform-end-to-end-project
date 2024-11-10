# CREATING SECURITY GROUP FOR BASTION HOST------------------------------------------------------------------
resource "aws_security_group" "bastion_host_sg" {
  name        = "bastion-host-sg"
  description = "Allow SSH Traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "apci-bastion-host-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_host_allow_ssh" {
  security_group_id = aws_security_group.bastion_host_sg.id
  cidr_ipv4         = "18.206.107.24/29" # EC2 Instance Connect Service IP address for your Region. Do not use quad zero (0.0.0.0/0).
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_host_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.bastion_host_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# CREATING A BASTION HOST----------------------------------------------------------------------------------
resource "aws_instance" "bastion_host" {
  ami                     = var.image_id
  instance_type           = var.instance_type
  subnet_id = var.frontend_subnet_az_1a_id
  security_groups = [aws_security_group.bastion_host_sg.id]
  key_name = var.key_name
  associate_public_ip_address = true


   tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-bastion-host"
  })
}

# CREATING PRIVATE SERVER SECURITY GROUP------------------------------------------------------------------
resource "aws_security_group" "private_server_sg" {
  name        = "private-server-sg"
  description = "Allow SSH Traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "apci-private-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_server_allow_ssh" {
  security_group_id = aws_security_group.bastion_host_sg.id
  referenced_security_group_id = aws_security_group.bastion_host_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "private_server_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.private_server_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# CREATING A PRIVATE SERVER IN AVAILABILITY ZONE 1A-------------------------------------------------
resource "aws_instance" "private_server_az_1a" {
  ami                     = var.image_id
  instance_type           = var.instance_type
  subnet_id = var.backend_subnet_az_1a_id
  security_groups = [aws_security_group.private_server_sg.id]
  key_name = var.key_name
  associate_public_ip_address = false

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-private-server-az-1a"
  })
}

# CREATING A PRIVATE SERVER IN AVAILABILITY ZONE 1B-------------------------------------------------
resource "aws_instance" "private_server_az_1b" {
  ami                     = var.image_id
  instance_type           = var.instance_type
  subnet_id = var.backend_subnet_az_1b_id
  security_groups = [aws_security_group.private_server_sg.id]
  key_name = var.key_name
  associate_public_ip_address = false

  tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-private-server-az-1b"
  })
}