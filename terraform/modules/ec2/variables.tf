variable "environment" {
  description = "Nome do ambiente (staging | production)"
  type        = string
}

variable "project_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "iam_instance_profile_name" {
  type = string
}

variable "key_pair_name" {
  type = string
}

variable "user_data" {
  type = string
}
