locals {
  ec2_instances = {
    for idx, subnet_id in var.private_subnet_ids :
    "ec2-${idx}" => subnet_id
  }
}

resource "aws_lb" "alb_main" {
  name                       = "alb-tf"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  depends_on                 = [aws_lb_target_group_attachment.tg_attachments]
  enable_deletion_protection = false
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg-tf"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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

resource "aws_lb_target_group_attachment" "tg_attachments" {
  for_each = aws_instance.private_ec2

  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = each.value.id
  port             = 80
}


resource "aws_instance" "private_ec2" {
  for_each = local.ec2_instances

  ami                         = "ami-0eb302fcc77c2f8bd"
  instance_type               = "t2.micro"
  subnet_id                   = each.value
  security_groups             = [var.ec2_security_group_id]
  associate_public_ip_address = false
  user_data                   = file("./userdata.sh")
  tags                        = {
    Name = "private-${each.key}"
  }
}

