variable "secret_name" {
  description = "The name of the secret"
  type        = string
}

variable "secret_string" {
  description = "The secret value as a string"
  type        = string
  sensitive   = true
}
