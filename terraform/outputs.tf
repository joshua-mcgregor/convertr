output "api_url" {
  description = "CloudFront URL for the API"
  value       = "https://${aws_cloudfront_distribution.api_cf.domain_name}"
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.upload_api_pool.id
}

output "client_id" {
  description = "Client ID for Cognito"
  value       = aws_cognito_user_pool_client.upload_api_client.id
}