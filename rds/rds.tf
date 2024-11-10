# CREATING A DATABASE SUBNET GROUP----------------------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [var.db_subnet_az_1a_id, var.db_subnet_az_1b_id]   # APCI Template

      tags = merge(var.tags,{
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-db-subnet-group"
  })
}

# CREATING A RDS (MYSQL) SECURITY GROUP-----------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow DB Traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "rds-sg"
  }
}

# CREATING INBOUND SECURITY GROUP FOR RDS---------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "allow_db_traffic" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = var.vpc_cidr_block 
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

# CREATING OUTBOUND SECURITY GROUP FOR RDS----------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "db_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# CREATING MYSQL RDS--------------------------------------------------------------------------------------------
resource "aws_db_instance" "rds_mysql" {                                # APCI Template
  allocated_storage    = 20
  db_name              = "rdsmysql"                                  # db name is alphanumeric (no dashes or special characters) 
  engine               = "mysql"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username
  password             = var.password
  parameter_group_name = var.parameter_group_name
  skip_final_snapshot  = true                     # If you are working in dev, set as false.
  multi_az = true                                 # For high availability set as true
  publicly_accessible  = false                    # Do not make databases publicly accessible
  storage_type         = "gp2"
#   backup_retention_period = 0
#   backup_window = "00:00-00:10" # window for frequent backups set to every 10 minutes
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # rds security group ID
  
#   # Specify an S3 bucket for backups
#   s3_import {
#     bucket_name = "mysql-automated-backup"
#     source_engine = "mysql"
#     source_engine_version = "8.0"
#     ingestion_role = aws_iam_role.s3RDS_backup.arn
#   }

#   iam_database_authentication_enabled = true
  


   tags = merge(var.tags,{
    Name = "${var.tags["project"]}-${var.tags["application"]}-${var.tags["environment"]}-rds-mysql"
  })
}