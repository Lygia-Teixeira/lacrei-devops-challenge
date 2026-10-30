#!/bin/bash
# Rollback manual local (alternativa ao workflow rollback.yml no GitHub Actions).
# Requer AWS CLI configurado com credenciais que tenham permissao de ssm:SendCommand.
#
# Uso:
#   ./scripts/rollback.sh <staging|production> <tag-da-imagem>
set -euo pipefail

ENVIRONMENT="${1:?Informe o ambiente: staging ou production}"
IMAGE_TAG="${2:?Informe a tag da imagem (SHA do commit) para reverter}"
PROJECT_NAME="lacrei-devops-challenge"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
  echo "Ambiente invalido: $ENVIRONMENT (use staging ou production)" >&2
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}:${IMAGE_TAG}"

echo "Verificando se a imagem existe no ECR..."
aws ecr describe-images \
  --repository-name "$PROJECT_NAME" \
  --image-ids imageTag="$IMAGE_TAG" \
  --region "$AWS_REGION" >/dev/null

INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-${ENVIRONMENT}" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region "$AWS_REGION")

echo "Executando rollback em $ENVIRONMENT (instancia $INSTANCE_ID) para a imagem $IMAGE_URI"

aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "{\"commands\":[\"/opt/${PROJECT_NAME}/deploy.sh ${IMAGE_URI}\"]}" \
  --comment "Rollback manual (script local) para $IMAGE_TAG em $ENVIRONMENT" \
  --region "$AWS_REGION"

echo "Comando de rollback enviado. Acompanhe com: aws ssm list-command-invocations --instance-id $INSTANCE_ID --details"
