variable "domain_name" {
  description = "Primary domain name for ACM certificate"
  type        = string
}

variable "validation_method" {
  description = "Validation method for ACM certificate"
  type        = string
  default     = "DNS"
}



variable "tags" {
  description = "Tags to apply to the ACM certificate"
  type        = map(string)
  default     = {}
}
