resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-mysql-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-mysql-subnet-group"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-mysql-sg"
  description = "MySQL access from VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-mysql-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage + 50
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az = var.multi_az

  publicly_accessible = false
  storage_encrypted  = true

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  backup_retention_period = var.backup_retention_days
  deletion_protection     = true

  skip_final_snapshot = false
  final_snapshot_identifier = "${var.name}-mysql-final"

  apply_immediately = true

  tags = {
    Name        = "${var.name}-mysql"
    Environment = var.environment
  }
}
