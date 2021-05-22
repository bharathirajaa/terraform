provider "aws" {
  region = "ap-south-1"
  access_key = "AKIAVD6YJERDV7FRZDRY"
  secret_key = "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"
}

#VPC Creation
resource "aws_vpc" "vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc"
  }
}

#Public Subnet-1
resource "aws_subnet" "public_subnet-1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.1.0.0/24"
  tags = {
    Name = "public_subnet-1"
  }
}

#Public Subnet-2
resource "aws_subnet" "public_subnet-2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name = "public_subnet-2"
  }
}

#Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.1.2.0/24"
  tags = {
    Name = "private_subnet"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "IGW"
  }
}

#Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public_Route_Table"
  }
}

#Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
 # route {
  #  cidr_block = "0.0.0.0/0"
   # gateway_id = aws_nat_gateway.ngw.id
  #}
  tags = {
    Name = "Private_Route_Table"
  }
}

#Route Table Association - Public Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet-1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet-2.id
  route_table_id = aws_route_table.public_rt.id
}

#Route Table Association - Private Subnet
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

#Elastic IP
#resource "aws_eip" "eip" {
#  vpc      = true
#}

#NAT Gateway Association
# allocation_id = aws_eip.eip.id
# subnet_id     = aws_subnet.public_subnet.id
#}

#Security Group
resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "FIRST-SG"
  }
}

#Launch Instance -1
resource "aws_instance" "winsrv-1" {
  ami = "ami-034a4d85b5ef5e779"
   key_name = "demo"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.public_subnet-1.id
  tags = {
    "Name" = "Windows Server 1"
  }
}

#Elastic IP -1
resource "aws_eip" "eip-1" {
  vpc      = true
  tags = {
    "Name" = "eip-1"
  }
}

#Launch Instance -2
resource "aws_instance" "winsrv-2" {
  ami = "ami-034a4d85b5ef5e779"
   key_name = "demo"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.public_subnet-2.id
  tags = {
    "Name" = "Windows Server 2"
  }
}

#Elastic IP -2
resource "aws_eip" "eip-2" {
  vpc      = true
  tags = {
    "Name" = "eip-2"
  }
}

#Target Group
resource "aws_lb_target_group" "tgroup" {
 name     = "TargetGroup-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }
}

#target group and attache
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.tgroup.arn
  target_id        = aws_instance.winsrv-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "test1" {
  target_group_arn = aws_lb_target_group.tgroup.arn
  target_id        = aws_instance.winsrv-2.id
  port             = 80
}

#Application Load Balancer
resource "aws_lb" "app" {
  name = "main-app-lb"
  internal   = false
   load_balancer_type = "application"
   security_groups    = ["${aws_security_group.sg.id}"]
  subnets            = ["${aws_subnet.public_subnet-1.id}","${aws_subnet.public_subnet-2.id}"]
}

#Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgroup.arn
  }
}