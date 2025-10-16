resource "aws_cognito_user_pool" "upload_api_pool" {
  name = "upload-api-user-pool"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "upload_api_client" {
  name         = "upload-api-client"
  user_pool_id = aws_cognito_user_pool.upload_api_pool.id

  explicit_auth_flows           = ["ADMIN_NO_SRP_AUTH"]
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user" "test_user" {
  user_pool_id         = aws_cognito_user_pool.upload_api_pool.id
  username             = "test-user"
  force_alias_creation = true

  attributes = {
    email = "testuser@test.com"
  }

  password = var.test_user_password
}

