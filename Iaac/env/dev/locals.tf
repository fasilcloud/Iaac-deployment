data "aws_availability_zones" "available" {}

locals {
  name        = "saas-app"
  region      = "us-east-1"
  k8s_version = "1.33"

  vpc_cidr = "172.17.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    app-name = local.name

  }
}
