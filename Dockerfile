# --- Estágio 1: build/dependências ---
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund

# --- Estágio 2: imagem final de execução ---
FROM node:24-alpine AS runtime

# Atualiza os pacotes do sistema e remove npm/npx/corepack/yarn, que não são
# usados em execução e trazem dependências próprias com CVEs (menor superfície de ataque)
RUN apk upgrade --no-cache && \
    apk add --no-cache dumb-init && \
    rm -rf /usr/local/lib/node_modules /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn-* && \
    addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
ENV NODE_ENV=production \
    PORT=3000

COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/status', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "src/server.js"]
