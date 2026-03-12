
locals {
  env              = terraform.workspace
  secret_full_name = "${var.project_name}-${local.env}-${var.secret_name}"
}

resource "aws_secretsmanager_secret" "supabase_db" {
  name        = local.secret_full_name
  description = var.secret_description

  tags = {
    Environment = local.env
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "supabase_db_version" {
  secret_id = aws_secretsmanager_secret.supabase_db.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}
