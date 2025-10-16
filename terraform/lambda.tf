resource "aws_lambda_function" "upload_api" {
  function_name = "lambda-convertr-upload-picture"
  filename      = "/tmp/dist/lambda.zip"
  handler       = "lambda_function.handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30

  source_code_hash = base64sha256(var.git_commit)

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.pictures.bucket
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}