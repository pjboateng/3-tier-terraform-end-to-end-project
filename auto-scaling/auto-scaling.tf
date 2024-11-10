# CREATING SECURITY GROUP FOR JUPITER SERVER (PUBLIC SERVER)----------------------------------------------------------
resource "aws_security_group" "jupiter_server_sg" {
  name        = "jupiter-server-sg"
  description = "Allow SSH, HTTP, and HTTPS traffic"
  vpc_id      = var.vpc_id

 tags = {
    Name = "apci-jupiter-server-sg"
  }
}

# CREATING INBOUND RULES FOR JUPITER SERVER---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.jupiter_server_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.jupiter_server_sg.id
  referenced_security_group_id = var.alb_sg_id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.jupiter_server_sg.id
  referenced_security_group_id = var.alb_sg_id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# CREATING OUTBOUND RULES FOR JUPITER SERVER-----------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.jupiter_server_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# CREATING LAUNCH TEMPLATE FOR JUPITER SERVER----------------------------------------------------------------------------
resource "aws_launch_template" "apci_lt" {
  name_prefix   = "apci-lt"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name = var.key_name            # Unique key pair created on the AWS console
  user_data = base64encode(file("scripts/frontend-server.sh"))

  # Add any additional requirements from the Terraform Registry such as EBS volume, cpu options, etc

    network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.jupiter_server_sg.id]
  }

   tag_specifications {                       # Added from terraform registry
    resource_type = "instance"

 tags = merge(var.tags, {
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-jupiter-server" # Check to see if this will show up on the console
  })
}
}

# CREATING AUTO-SCALING GROUP--------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "apci_asg" {
  name                      = "apci-asg"
  max_size                  = 6
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  vpc_zone_identifier       = [var.frontend_subnet_az_1a_id, var.frontend_subnet_az_1b_id]
  target_group_arns         = var.target_group_arn

  launch_template {
    id      = aws_launch_template.apci_lt.id
    version = "$Latest"
  }
}