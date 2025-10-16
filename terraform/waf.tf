resource "aws_wafv2_web_acl" "api_acl" {
  provider = aws.us_east_1

  name        = "upload-api-waf"
  description = "WAF for CloudFront"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "upload-api-waf"
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {} # don't override allow/block actions
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "aws-managed-rules"
    }
  }

  rule {
    name     = "RateLimit"
    priority = 2

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "rate-limit"
    }
  }
}
