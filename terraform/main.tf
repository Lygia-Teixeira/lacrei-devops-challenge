locals {
  environments = ["staging", "production"]
}

module "ec2" {
  source   = "./modules/ec2"
  for_each = toset(local.environments)

  environment                = each.key
  project_name               = var.project_name
  ami_id                     = data.aws_ami.amazon_linux_2023.id
  instance_type              = var.instance_type
  subnet_id                  = aws_subnet.public.id
  security_group_ids         = [aws_security_group.web.id]
  iam_instance_profile_name  = aws_iam_instance_profile.ec2_profile.name
  key_pair_name              = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    project_name       = var.project_name
    environment        = each.key
    aws_region         = var.aws_region
    ecr_repository_url = aws_ecr_repository.app.repository_url
    domain_name        = each.key == "production" ? var.domain_name : "staging.${var.domain_name}"
  }))
}

output "staging_public_ip" {
  value = module.ec2["staging"].public_ip
}

output "production_public_ip" {
  value = module.ec2["production"].public_ip
}
