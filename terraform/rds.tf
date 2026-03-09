
resource "aws_db_instance" "supabase_db" {
  identifier        = "supabase-prod-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "15.3"
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

