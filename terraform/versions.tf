terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend remoto recomendado para uso em equipe (state compartilhado e travado).
  # Descomente e ajuste após criar o bucket S3 e a tabela DynamoDB de lock.
  # backend "s3" {
  #   bucket         = "lacrei-devops-challenge-tfstate"
  #   key            = "global/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "lacrei-devops-challenge-tf-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
