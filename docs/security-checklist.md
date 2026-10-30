# Checklist de Segurança Aplicado

| # | Item | Status | Onde |
|---|------|--------|------|
| 1 | Sem credenciais AWS de longa duração no GitHub — autenticação via OIDC | ✅ | [github_oidc.tf](../terraform/github_oidc.tf), workflow usa `aws-actions/configure-aws-credentials` com `role-to-assume` |
| 2 | Secrets sensíveis (IDs de instância, ARN de role) via GitHub Secrets, nunca hardcoded | ✅ | `.github/workflows/ci-cd.yml`, `.github/workflows/rollback.yml` |
| 3 | Princípio do menor privilégio nas roles IAM | ✅ | [iam.tf](../terraform/iam.tf) (EC2: ECR read-only + CloudWatch + SSM), [github_oidc.tf](../terraform/github_oidc.tf) (deploy role restrita a push no ECR e SendCommand) |
| 4 | Role do GitHub Actions restrita à branch `main` do repositório | ✅ | Condição `token.actions.githubusercontent.com:sub` em `github_oidc.tf` |
| 5 | SSH desabilitado como via principal de acesso — administração via SSM Session Manager | ✅ | `iam.tf` (`AmazonSSMManagedInstanceCore`), porta 22 restrita a CIDR único em `security_groups.tf` |
| 6 | IMDSv2 obrigatório nas instâncias (mitiga SSRF → roubo de credenciais) | ✅ | `http_tokens = "required"` em `modules/ec2/main.tf` |
| 7 | Volumes EBS criptografados | ✅ | `root_block_device.encrypted = true` em `modules/ec2/main.tf` |
| 8 | HTTPS/TLS obrigatório (Let's Encrypt via certbot + Nginx) | ✅ | `terraform/templates/user_data.sh.tpl` |
| 9 | CORS restrito a origens explícitas (sem `*`) | ✅ | [src/app.js](../src/app.js) — `CORS_ALLOWED_ORIGINS` |
| 10 | Cabeçalhos de segurança HTTP (helmet) | ✅ | `src/app.js` |
| 11 | Scan de vulnerabilidades da imagem Docker antes do push (Trivy, bloqueia CRITICAL/HIGH) | ✅ | `.github/workflows/ci-cd.yml` (job `build-and-scan`) |
| 12 | Scan de vulnerabilidades da imagem no registry (ECR scan on push) | ✅ | `image_scanning_configuration.scan_on_push = true` em `terraform/ecr.tf` |
| 13 | Tags de imagem imutáveis no ECR (evita sobrescrever uma imagem já implantada) | ✅ | `image_tag_mutability = "IMMUTABLE"` em `terraform/ecr.tf` |
| 14 | Usuário não-root dentro do container | ✅ | `Dockerfile` (`USER appuser`) |
| 15 | `.dockerignore` evita vazamento de segredos/arquivos sensíveis na imagem | ✅ | `.dockerignore` |
| 16 | Aprovação manual obrigatória antes de deploy em produção | ✅ (config manual) | GitHub Environment `production` com "required reviewers" — ver README, seção Setup |
| 17 | Logs sem dados sensíveis (sem tokens, senhas, PII completo) | ✅ | `src/app.js` (log estruturado só com método/rota/status/duração) |
| 18 | Alertas automáticos em caso de falha de instância ou erro de aplicação | ✅ | `terraform/monitoring.tf` (CloudWatch Alarms + SNS) |
| 19 | Segredos do `.env` nunca commitados (apenas `.env.example`) | ✅ | `.gitignore` |
| 20 | Dependências auditadas (`npm audit`) | ⚠️ Recomendado | Adicionar `npm audit --audit-level=high` ao workflow como hardening futuro |

## Itens que ficam a cargo de quem for aplicar o desafio na AWS real

Estes exigem acesso à console/conta AWS e ao repositório GitHub, que este ambiente de preparo não possui:

- Criar o par de chaves EC2 (`key_pair_name`) e restringir `ssh_allowed_cidr` ao IP real de quem administra.
- Configurar `required reviewers` no GitHub Environment `production` (Settings → Environments).
- Rodar `certbot --nginx -d SEU_DOMINIO` após o DNS apontar para o Elastic IP da instância.
- Cadastrar os secrets/vars no GitHub: `AWS_GITHUB_ACTIONS_ROLE_ARN`, `STAGING_INSTANCE_ID`, `PRODUCTION_INSTANCE_ID`, `APP_DOMAIN`.
