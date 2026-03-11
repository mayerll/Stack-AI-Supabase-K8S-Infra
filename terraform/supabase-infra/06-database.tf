
# ==========================================
# 1. RDS Security Group
# ==========================================
resource "aws_security_group" "rds_sg" {
  name        = "${local.env_prefix}-rds-sg"
  description = "Allow PostgreSQL traffic from within the VPC"
  vpc_id      = module.vpc.vpc_id

  # Ingress: Allow 5432 from the entire VPC CIDR
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  # Egress: Allow all outbound (Required for AWS internal communication)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# ==========================================
# 2. DB Subnet Group
# ==========================================
resource "aws_db_subnet_group" "db_subnets" {
  name       = "${local.env_prefix}-db-subnets"
  subnet_ids = module.vpc.private_subnets

  tags = local.common_tags
}

# ==========================================
# 3. RDS PostgreSQL Instance
# ==========================================
resource "aws_db_instance" "supabase_db" {
  identifier        = "${local.env_prefix}-db"
  allocated_storage = var.db_storage
  engine            = "postgres"
  engine_version    = var.postgres_version
  instance_class    = var.db_instance_class
  db_name           = "postgres"
  username          = "supabase_admin"
  password          = var.db_password

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  # High Availability & Backup
  # Since 'dev' no longer needs to save cost, we enable Multi-AZ for all envs
  multi_az               = true
  skip_final_snapshot    = terraform.workspace == "prod" ? false : true
  final_snapshot_identifier = "${local.env_prefix}-db-final-snapshot"
  backup_retention_period = 7

  # ==========================================
  # Dependency & Lifecycle
  # ==========================================
  
  # CRITICAL: RDS creation often fails if the NAT Gateways or Routing 
  # are still initializing. We wait for the entire VPC module.
  depends_on = [
    module.vpc,
    aws_db_subnet_group.db_subnets
  ]

  lifecycle {
    # 1. Prevents 'terraform destroy' from deleting the DB (Professional Safety)
    prevent_destroy = true 

    # 2. Ensures the password doesn't revert if changed via AWS Console/Secrets Manager
    ignore_changes = [password]

    # 3. If a change requires replacement, create the new DB before deleting the old one
    create_before_destroy = true
  }

  tags = local.common_tags
}

