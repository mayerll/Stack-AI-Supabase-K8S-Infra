
# ==========================================
# 04-storage.tf: S3 Bucket for Supabase
# ==========================================

# 1. Main Storage Bucket
# Naming: stackai-supabase-storage-<env>-<region>
resource "aws_s3_bucket" "storage" {
  bucket = "stackai-supabase-storage-${terraform.workspace}-${var.region}"

  tags = merge(local.common_tags, {
    Name        = "StackAI Supabase Storage"
    ManagedBy   = "Terraform"
    Environment = terraform.workspace
    Region      = var.region
  })

  # Lifecycle Protection: The "Ultimate Safety Lock"
  # This prevents 'terraform destroy' from deleting the bucket as long as this is true.
  # In a professional setup, we keep this TRUE for dev, staging, and prod to prevent 
  # catastrophic data loss.
  lifecycle {
    prevent_destroy = true
  }
}

# 2. Bucket Versioning
# Keeps previous versions of objects. Essential for recovering from accidental 
# application-level deletes or overwrites.
resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Server-Side Encryption (SSE-S3)
# Ensures data is encrypted at rest using AES-256. 
# Satisfies standard compliance requirements (SOC2, HIPAA, etc.)
resource "aws_s3_bucket_server_side_encryption_configuration" "storage_encryption" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Public Access Block (Security Hardening)
# This is an explicit "No Public Access" policy that overrides any potential 
# accidental bucket policy or ACL changes.
resource "aws_s3_bucket_public_access_block" "storage_access" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. Ownership Controls
# Ensures all objects uploaded to the bucket are owned by the bucket owner.
resource "aws_s3_bucket_ownership_controls" "storage_ownership" {
  bucket = aws_s3_bucket.storage.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

