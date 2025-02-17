data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*"] # amazon Linux 2023
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"         # 필터링할 항목의 이름
    values = ["opt-in-not-required"] # 필터 조건
  }
}

# VPC 생성 모듈을 정의. Terraform의 VPC 모듈을 사용해 VPC를 프로비저닝
module "my_vpc" {
  source  = "terraform-aws-modules/vpc/aws" # VPC 모듈의 소스 경로
  version = "5.14.0"                        # VPC 모듈의 버전

  name = "nickname-vpc" # VPC의 이름

  # VPC의 CIDR 블록을 10.0.0.0/16으로 설정
  cidr = "10.0.0.0/16"
  # 필터링된 가용 영역 중 상위 3개를 선택
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # 사설 서브넷의 CIDR 블록 정의
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  # 공용 서브넷의 CIDR 블록 정의
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  # NAT 게이트웨이를 활성화하고, 단일 NAT 게이트웨이를 사용
  # enable_nat_gateway   = true
  # single_nat_gateway   = true
  enable_dns_hostnames = true # DNS 호스트 이름을 활성화

  # 공용 서브넷의 태그. ELB 역할을 부여
  public_subnet_tags = {
    "Name" = "nickname-public-subnet"
  }

  # 사설 서브넷의 태그. 내부 ELB 역할을 부여
  private_subnet_tags = {
    "Name" = "nickname-private-subnet"
  }
}

resource "aws_instance" "opensearch_instance" {
  ami           = data.aws_ami.al2023.id # Amazon Linux 2023 AMI ID (us-east-1 리전 기준)
  instance_type = "m5.xlarge"            # 4 vCPU, 16GB RAM

  vpc_security_group_ids      = [aws_security_group.my_ec2_sg.id]
  associate_public_ip_address = true
  subnet_id                   = module.my_vpc.public_subnets[0]

  key_name = aws_key_pair.my_key.key_name

  root_block_device {
    volume_size = 50 # 50GB 시스템 스토리지
    volume_type = "gp3"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 100 # 100GB OpenSearch 스토리지
    volume_type = "gp3"
  }

  tags = {
    Name = "nickname-OpenSearch-Instance"
  }
}

resource "aws_security_group" "my_ec2_sg" {
  vpc_id = module.my_vpc.vpc_id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["118.235.0.0/16", "114.202.151.250/32"] # 내 IP 확인
  }
}

resource "random_integer" "unique" {
  min = 10000
  max = 99999
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-key-${random_integer.unique.result}"
  public_key = file("${path.module}/my-key.pub")
}

output "ssh_command_print" {
  value = "ssh -i ./my-key ec2-user@${aws_instance.opensearch_instance.public_dns}"
}
