
resource "aws_security_group" "rds_sg" {
  name        = "supabase-rds-sg"
  description = "Security group for Supabase RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # adjust for your security requirements
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "supabase-rds-sg"
  }
}

resource "aws_db_instance" "supabase_db" {
  identifier        = "supabase-prod-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "18.3"
  instance_class    = "db.t3.micro"
  db_name           = "postgres"
  username          = "supabase_admin"
  password          = "SuperSecretPassword123" # In production, use a variable

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "supabase-db-subnets"
  subnet_ids = module.vpc.private_subnets
}

