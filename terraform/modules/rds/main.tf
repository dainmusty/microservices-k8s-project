resource "aws_db_instance" "postgres" {
  identifier              = var.identifier
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  vpc_security_group_ids  = var.vpc_security_group_ids
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  multi_az                = var.multi_az
  storage_type            = var.storage_type
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  publicly_accessible     = var.publicly_accessible
  tags                    = var.db_tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.env}-${var.db_subnet_group_name}"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "${var.env}-rds-subnet-group"
  }
}

