#!/bin/bash
set -euxo pipefail

# --- Docker ---
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# --- CloudWatch Agent ---
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "agent": { "metrics_collection_interval": 60, "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/${project_name}-${environment}/app.log",
            "log_group_name": "/${project_name}/${environment}/app",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project_name}/${environment}",
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

mkdir -p /var/log/${project_name}-${environment}

# --- Nginx (proxy reverso + TLS via certbot) ---
dnf install -y nginx
systemctl enable --now nginx

cat > /etc/nginx/conf.d/app.conf <<'NGINXCONF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXCONF
systemctl reload nginx

dnf install -y python3-pip
pip3 install certbot certbot-nginx
# Emissao do certificado TLS: rodar manualmente apos o DNS do dominio apontar para o EIP desta instancia:
#   certbot --nginx -d SEU_DOMINIO --non-interactive --agree-tos -m SEU_EMAIL --redirect

# --- Primeiro start do container (placeholder ate o primeiro deploy do pipeline) ---
mkdir -p /opt/${project_name}
cat > /opt/${project_name}/deploy.sh <<'DEPLOYSCRIPT'
#!/bin/bash
set -euxo pipefail
IMAGE="$1"
CONTAINER_NAME="${project_name}-${environment}"

aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

docker pull "$IMAGE"

docker rm -f "$CONTAINER_NAME" || true

docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p 3000:3000 \
  -e NODE_ENV=${environment} \
  -e PORT=3000 \
  -e CORS_ALLOWED_ORIGINS="https://${domain_name}" \
  -e APP_VERSION="$IMAGE" \
  --log-driver awslogs \
  --log-opt awslogs-group="/${project_name}/${environment}/app" \
  --log-opt awslogs-create-group=true \
  "$IMAGE"
DEPLOYSCRIPT
chmod +x /opt/${project_name}/deploy.sh
