resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.iam_instance_profile_name
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  user_data                   = var.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # força IMDSv2 (mitiga SSRF -> credential theft)
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 20
    volume_type            = "gp3"
    encrypted              = true
    delete_on_termination  = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    Environment = var.environment
  }
}
