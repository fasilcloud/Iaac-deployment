module "acm_saas_app" {
  source = "../../modules/acm"

  domain_name = "*.saasapp.com"


}

output "domain_validation_options" {
  description = "Domain validation options for the ACM certificate"
  value       = module.acm_saas_app.domain_validation_options
}

output "acm_arn" {
  description = "ARN for saas-app ACM certificate"
  value       = module.acm_saas_app.certificate_arn
}



# VPC for Cluster
data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.2"

  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 3)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                  = 1
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"         = 1
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }

}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.3"

  depends_on = [ module.vpc ]

  cluster_name                   = "${local.name}-eks"
  cluster_version                = local.k8s_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = true
  create_node_security_group    = true
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true
cluster_endpoint_public_access_cidrs = [
  "172.17.0.0/16"   # single IP
]
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    eks-node = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  tags = local.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.21"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  enable_kube_prometheus_stack        = true

  aws_load_balancer_controller = {
    chart         = "aws-load-balancer-controller"
    chart_version = "1.13.4"
    repository    = "https://aws.github.io/eks-charts"
    namespace     = "kube-system"
    wait          = true
    wait_for_jobs = true
    values = [
      yamlencode({
        clusterName = module.eks.cluster_name
        region      = local.region
        vpcId       = module.vpc.vpc_id
        replicaCount = 1
      })
    ]
  }

  # Metrics Server (IMPORTANT for EKS)
  metrics_server = {
    chart_version = "3.12.1"
    namespace     = "kube-system"
    wait          = true

    values = [
      yamlencode({
        args = [
          "--kubelet-insecure-tls",
          "--kubelet-preferred-address-types=InternalIP"
        ]
      })
    ]
  }

  
  tags = {
    "kubernetes.io/cluster/${local.name}-eks" = "shared"
  }
}


data "aws_secretsmanager_secret" "db_username" {
  name = "dev/mysql/saas-app/username"
}

data "aws_secretsmanager_secret_version" "db_username" {
  secret_id = data.aws_secretsmanager_secret.db_username.id
}

data "aws_secretsmanager_secret" "db_password" {
  name = "dev/mysql/saas-app/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

module "mysql" {
  source = "../../modules/mysql"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = local.vpc_cidr
  private_subnet_ids = module.vpc.private_subnets

  db_name     = "saasdb"
  db_username = data.aws_secretsmanager_secret_version.db_username.secret_string
  db_password = data.aws_secretsmanager_secret_version.db_password.secret_string

  environment = "dev"
}

module "route53_public" {
  source = "../../modules/route53"

  domain_name = "saasapp.com"

  
}
