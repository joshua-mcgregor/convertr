resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Allow Lambda to access S3"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description     = "Allow HTTPS to S3 via VPC endpoint"
  }
}