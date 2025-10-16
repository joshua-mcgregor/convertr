
variable "git_commit" {
  description = "Current Git commit hash"
  type        = string
  default     = "dev"
}

variable "test_user_password" {
  description = "Password for the test user"
  type        = string
  default     = ""
}