# OpenSearch 도메인 생성
resource "aws_opensearch_domain" "example" {
  domain_name    = "example-domain"
  engine_version = "OpenSearch_2.17"

  cluster_config {
    instance_type  = "r7g.large.search"
    instance_count = 3

    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  # vpc_options {
  #   subnet_ids = module.vpc.private_subnets

  #   security_group_ids = [aws_security_group.opensearch_sg.id]
  # }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.opensearch_master_user
      master_user_password = var.opensearch_master_password
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Domain = "example-domain"
  }
}

# # OpenSearch 보안 그룹 생성
# resource "aws_security_group" "opensearch_sg" {
#   name        = "opensearch-sg"
#   description = "Allow inbound traffic to OpenSearch"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "Allow traffic from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     #cidr_blocks = [module.vpc.vpc_cidr_block]
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "opensearch-sg"
#   }
# }

# OpenSearch 액세스 정책
resource "aws_opensearch_domain_policy" "main" {
  domain_name = aws_opensearch_domain.example.domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "es:ESHttp*"
        ]
        Resource = "${aws_opensearch_domain.example.arn}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = ["{var.my_ip}/32", "0.0.0.0/0"]
          }
        }
      }
    ]
  })
}



# 기존 코드는 그대로 유지하고 아래 내용을 추가합니다.

# Fluent Bit IAM 정책 생성
resource "aws_iam_policy" "fluent_bit_policy" {
  name        = "fluent-bit-policy"
  path        = "/"
  description = "IAM policy for Fluent Bit"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "es:ESHttp*"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.example.domain_name}"
      }
    ]
  })
}

# Fluent Bit용 IRSA 설정
module "irsa_fluent_bit" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.47.1"

  create_role                   = true
  role_name                     = "fluent-bit-irsa"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [aws_iam_policy.fluent_bit_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:logging:fluent-bit"]
}

# Kubernetes 네임스페이스 생성
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }

  depends_on = [null_resource.eks_kubectl_config]
}

# Kubernetes 서비스 계정 생성
resource "kubernetes_service_account" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.logging.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa_fluent_bit.iam_role_arn
    }
  }
  depends_on = [kubernetes_namespace.logging]
}

# 데이터 소스 추가
data "aws_caller_identity" "current" {}

output "elasticsearch_dashboard" {
  value = "https://${aws_opensearch_domain.example.dashboard_endpoint}"
}
