variable "domain_name" {
  description = "Public domain name (example: saasapp.com)"
  type        = string
}

variable "comment" {
  description = "Optional comment for hosted zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "Tags for hosted zone"
  type        = map(string)
  default     = {}
}
