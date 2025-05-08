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
