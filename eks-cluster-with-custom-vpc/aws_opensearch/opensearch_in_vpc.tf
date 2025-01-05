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

  vpc_options {
    subnet_ids = module.vpc.private_subnets

    security_group_ids = [aws_security_group.opensearch_sg.id]
  }

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

# OpenSearch 보안 그룹 생성
resource "aws_security_group" "opensearch_sg" {
  name        = "opensearch-sg"
  description = "Allow inbound traffic to OpenSearch"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #cidr_blocks = [module.vpc.vpc_cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "opensearch-sg"
  }
}
