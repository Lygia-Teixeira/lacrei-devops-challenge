# SG único reaproveitado por staging e produção (mesmas regras de borda;
# o isolamento real entre ambientes é feito por instância/EIP/DNS separados).
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Permite HTTPS/HTTP publico e SSH restrito para instancias da aplicacao"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS publico"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP publico (somente para redirect e desafio ACME do certbot)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH restrito ao CIDR autorizado (acesso emergencial; uso normal via SSM)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "Saida livre (pull de imagens Docker, pacotes, CloudWatch, SSM)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-web-sg"
    Project = var.project_name
  }
}
