resource "aws_s3_bucket" "pictures" {
  bucket = "convertr-picture-bucket-eu-west-2"
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket              = aws_s3_bucket.pictures.id
  block_public_acls   = true
  block_public_policy = true
}