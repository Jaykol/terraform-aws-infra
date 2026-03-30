terraform {
  required_providers {
    aws = {
     source = "hashicorp/aws"
     version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}


provider "aws" {
  region = var.aws_region
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }
}


#VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

#Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
    Project = var.project_name
  }
}

#Public Subnets
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Project = var.project_name
  }
}

#Private Subnets
resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { 
    Name = "${var.project_name}-private-${count.index + 1}"
    Project = var.project_name
  }
}


#Route Table
resource "aws_route_table" "public" {
  vpc_id =aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#---EC2 Security Group(SG)--------
resource "aws_security_group" "ec2" {
  name = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id = aws_vpc.main.id
  
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description	= "HTTP"
    from_port =	80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    description = "HTTP"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    description = "Flask app"
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { 
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
    Project = var.project_name
  }
}

#RDS SECURITY GROUP---------
resource "aws_security_group" "rds" {
  name = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id = aws_vpc.main.id

  ingress { 
    description = "PostgreSQL from EC2"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

#--EC2 Key Pair --------------
resource "aws_key_pair" "main" {
  key_name = "${var.project_name}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

#--EC2 instance---------
resource "aws_instance" "app" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name = aws_key_pair.main.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "${var.project_name}-ec2"
    Project = var.project_name
  }
}

#---RDS Subnet Group--------
resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

#RDS Instance -----------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db"
  engine = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"
  allocated_storage = 20

  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-db"
    Project = var.project_name
  }
}
