
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # More secure: only allow VPC internal traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "supabase_db" {
  identifier        = "${var.project_name}-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = var.postgres_version
  instance_class    = var.db_instance_class
  db_name           = "postgres"
  username          = "supabase_admin"
  password          = var.db_password

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = module.vpc.private_subnets
}

