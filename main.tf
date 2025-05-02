provider "aws" {
  region     = "ap-northeast-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"
}

resource "aws_subnet" "private_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "private_4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-northeast-2c"
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb_sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_sg"
  description = "Allow ALB traffic to EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb_main" {
  name                       = "alb-tf"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  depends_on = [
    aws_lb_target_group_attachment.ec2_instance_1,
    aws_lb_target_group_attachment.ec2_instance_2
  ]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg-tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "ec2_instance_1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.private_ec2_sub1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_instance_2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.private_ec2_sub2.id
  port             = 80
}

resource "aws_instance" "private_ec2_sub1" {
  ami                         = "ami-0eb302fcc77c2f8bd"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_1.id
  security_groups             = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  user_data                   = file("./userdata.sh")
}

resource "aws_instance" "private_ec2_sub2" {
  ami                         = "ami-0eb302fcc77c2f8bd"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_2.id
  security_groups             = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  user_data                   = file("./userdata.sh")
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

#resource "aws_db_instance" "rds" {
#  identifier           = "tf-rds"
#  engine               = "mysql"
#  instance_class       = "db.t4g.micro" # free-tier
#  allocated_storage    = 20
#  username             = var.aws_rds_username
#  password             = var.aws_rds_password
#  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
#  skip_final_snapshot  = true
#}
#
#resource "aws_db_subnet_group" "rds_subnet_group" {
#  name       = "tf-rds-subnet-group"
#  subnet_ids = [aws_subnet.private_3.id, aws_subnet.private_4.id]
#}
