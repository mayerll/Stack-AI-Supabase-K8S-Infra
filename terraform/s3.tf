
resource "aws_s3_bucket" "storage" {
  bucket = "supabase-storage-stack-ai-${random_id.suffix.hex}"
}

resource "random_id" "suffix" { byte_length = 4 }

