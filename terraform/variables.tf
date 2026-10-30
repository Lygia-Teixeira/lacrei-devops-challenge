variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto, usado como prefixo para tags e nomes de recursos"
  type        = string
  default     = "lacrei-devops-challenge"
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block da subnet pública"
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instância EC2 usado em staging e produção"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Nome do par de chaves EC2 já existente na conta AWS, usado para acesso SSH emergencial"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorizado a acessar a porta 22 (ideal: IP fixo do bastion/VPN, nunca 0.0.0.0/0)"
  type        = string
}

variable "alert_email" {
  description = "E-mail que recebe alertas do SNS (CloudWatch alarms)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domínio base usado para emissão de certificado TLS via Let's Encrypt (ex: exemplo.com.br)"
  type        = string
  default     = ""
}
