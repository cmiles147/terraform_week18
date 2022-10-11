terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "week18_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "week18_vpc"
  }
}

# Public subnet 1 and 2
resource "aws_subnet" "Public1" {
  vpc_id     = aws_vpc.week18_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "Public_subnet1"
  }
}

resource "aws_subnet" "Public2" {
  vpc_id     = aws_vpc.week18_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true 

 tags = {
    Name = "Public_subnet2"
  }
}

# Private subnet 1 and 2
resource "aws_subnet" "Private1" {
  vpc_id     = aws_vpc.week18_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false 

  tags = {
    Name = "Private_subnet1"
  }
}

resource "aws_subnet" "Private2" {
  vpc_id     = aws_vpc.week18_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false 

  tags = {
    Name = "Private_subnet2"
  }
}

# Route table
resource "aws_route_table" "week18_rt" {
  vpc_id = aws_vpc.week18_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.week18_igw.id
  }
  
   tags = {
    Name = "PublicRT"
  }
}

# Internet gateway
resource "aws_internet_gateway" "week18_igw" {
  vpc_id = aws_vpc.week18_vpc.id

  tags = {
    Name = "week18_igw"
  }
}

# Route table associations
resource "aws_route_table_association" "Pub_1_Association" {
  subnet_id      = aws_subnet.Public1.id
  route_table_id = aws_route_table.week18_rt.id
}

resource "aws_route_table_association" "Pub_2_Association" {
  subnet_id      = aws_subnet.Public2.id
  route_table_id = aws_route_table.week18_rt.id
}

# VPC security group
resource "aws_security_group" "week18_sg" {
  name        = "week18_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.week18_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
   ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

# Load balancer
resource "aws_lb" "week18_LB" {
  name               = "week18-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.week18_sg.id]
  subnets            = [aws_subnet.Public1.id, aws_subnet.Public2.id]
 
 }
  
 # RDS database
 resource "aws_db_instance" "week18_rds" {
  allocated_storage      = 10
  db_subnet_group_name   = "week18_rds_subnet"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# RDS security group
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow web tier traffic"
  vpc_id      = aws_vpc.week18_vpc.id

 
 ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.week18_sg.id]
    cidr_blocks      = ["0.0.0.0/0"]
  }

ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.week18_sg.id]
    cidr_blocks      = ["10.0.0.0/16"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}

# Add db to subnet group
resource "aws_db_subnet_group" "week18_rds_subnet" {
  name       = "week18_rds_subnet"
  subnet_ids = [aws_subnet.Private1.id, aws_subnet.Private2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# EC2 instances public subnet
resource "aws_instance" "Public1_EC2" {
  ami               = "ami-026b57f3c383c2eec"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  security_groups   = [aws_security_group.week18_sg.id]
  subnet_id         = aws_subnet.Public1.id

  tags = {
    Name = "Public1_EC2"
  }
}

resource "aws_instance" "Public2_EC2" {
  ami               = "ami-026b57f3c383c2eec"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1b"
  security_groups   = [aws_security_group.week18_sg.id]
  subnet_id         = aws_subnet.Public2.id

  tags = {
    Name = "Public2_EC2"
  }
}