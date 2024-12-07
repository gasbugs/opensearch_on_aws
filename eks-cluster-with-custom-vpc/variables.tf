variable "aws_region" {
  description = "Region for AWS"
  type        = string
}

variable "opensearch_master_user" {
  description = "오픈서치의 master 유저 이름"
}

variable "opensearch_master_password" {
  description = "오픈서치의 master 패스워드"
}

variable "my_ip" {
  description = "허용할 내 IP"
}
