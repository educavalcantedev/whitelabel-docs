#!/usr/bin/env bash
set -euo pipefail

DOCS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Pasta pai de whitelabel-docs com gateway, auth, clients, etc.
ROOT="${WHITELABEL_MONOREPO_ROOT:-$(cd "$DOCS_ROOT/.." && pwd)}"
MASTER="${DOCS_ROOT}/.env.master"

if [[ ! -f "$MASTER" ]]; then
  echo "Arquivo não encontrado: $MASTER"
  echo ""
  echo "Crie a partir do template:"
  echo "  cd whitelabel-docs && cp .env.master.example .env.master"
  echo "  # edite .env.master e preencha SUPABASE_PROJECT_REF e SUPABASE_PUBLISHABLE_KEY"
  exit 1
fi

# Carrega KEY=VALUE (suporta valores entre aspas)
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    value="${value%\"}"; value="${value#\"}"
    value="${value%\'}"; value="${value#\'}"
    export "$key=$value"
  fi
done <"$MASTER"

require() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "$value" ]]; then
    echo "Erro: $name não está definido em .env.master"
    exit 1
  fi
}

require SUPABASE_PROJECT_REF
require SUPABASE_PUBLISHABLE_KEY

SUPABASE_URL="https://${SUPABASE_PROJECT_REF}.supabase.co"
SUPABASE_JWKS_URL="${SUPABASE_URL}/auth/v1/.well-known/jwks.json"
SUPABASE_ISSUER="${SUPABASE_URL}/auth/v1"

MOBILE_GATEWAY_URL="${API_GATEWAY_URL_MOBILE:-$API_GATEWAY_URL}"

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "  ✓ $path"
}

echo "Monorepo: ${ROOT}"
echo "Gerando arquivos .env a partir de ${MASTER}..."
echo ""

# --- Clients ---
write_file "${ROOT}/whitelabel-clients/apps/web/.env.local" <<EOF
VITE_SUPABASE_URL=${SUPABASE_URL}
VITE_SUPABASE_ANON_KEY=${SUPABASE_PUBLISHABLE_KEY}
VITE_API_GATEWAY_URL=${API_GATEWAY_URL}
VITE_APP_NAME=${APP_NAME}
VITE_APP_LOGO_URL=${APP_LOGO_URL}
EOF

# react-native-config lê apps/mobile/.env (não .env.local)
write_file "${ROOT}/whitelabel-clients/apps/mobile/.env" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_PUBLISHABLE_KEY}
API_GATEWAY_URL=${MOBILE_GATEWAY_URL}
APP_NAME=${APP_NAME}
APP_VERSION=1.0.0
EOF

# Mantém .env.local alinhado (alguns IDEs abrem este arquivo)
write_file "${ROOT}/whitelabel-clients/apps/mobile/.env.local" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_PUBLISHABLE_KEY}
API_GATEWAY_URL=${MOBILE_GATEWAY_URL}
APP_NAME=${APP_NAME}
APP_VERSION=1.0.0
EOF

write_file "${ROOT}/whitelabel-clients/apps/admin/.env.local" <<EOF
VITE_SUPABASE_URL=${SUPABASE_URL}
VITE_SUPABASE_ANON_KEY=${SUPABASE_PUBLISHABLE_KEY}
VITE_API_GATEWAY_URL=${API_GATEWAY_URL}
VITE_ADMIN_ROLE=${ADMIN_ROLE:-superadmin}
EOF

# --- Backend ---
write_file "${ROOT}/whitelabel-gateway/.env" <<EOF
AUTH_SERVICE_URL=${AUTH_SERVICE_URL}
CORE_SERVICE_URL=${CORE_SERVICE_URL}

SUPABASE_JWKS_URL=${SUPABASE_JWKS_URL}
SUPABASE_ISSUER=${SUPABASE_ISSUER}

RATE_LIMIT_REQUESTS_PER_SECOND=${RATE_LIMIT_REQUESTS_PER_SECOND}
CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS}

SPRING_PROFILES_ACTIVE=local,observability

SERVER_PORT=8080
EOF

write_file "${ROOT}/whitelabel-auth-service/.env" <<EOF
SUPABASE_JWKS_URL=${SUPABASE_JWKS_URL}
SUPABASE_ISSUER=${SUPABASE_ISSUER}

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_auth
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

WEB_LOGIN_TOKEN_TTL_SECONDS=${WEB_LOGIN_TOKEN_TTL_SECONDS:-60}
WEB_ACCESS_GRANT_HOURS=${WEB_ACCESS_GRANT_HOURS:-12}
VERIFICATION_CODE_PEPPER=${VERIFICATION_CODE_PEPPER:-change-me-in-production}

NOTIFY_SERVICE_URL=${NOTIFY_SERVICE_URL}
APP_NAME=${APP_NAME}
INTERNAL_SERVICE_API_KEY=${INTERNAL_SERVICE_API_KEY}
SPRING_PROFILES_ACTIVE=local,observability

SERVER_PORT=8084
EOF

write_file "${ROOT}/whitelabel-core-service/.env" <<EOF
SUPABASE_JWKS_URL=${SUPABASE_JWKS_URL}
SUPABASE_ISSUER=${SUPABASE_ISSUER}

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_core
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}

APP_NAME=${APP_NAME}
APP_LOGO_URL=${APP_LOGO_URL}
APP_PRIMARY_COLOR=${APP_PRIMARY_COLOR:-#2563eb}
AUTH_SERVICE_URL=${AUTH_SERVICE_URL}
INTERNAL_SERVICE_API_KEY=${INTERNAL_SERVICE_API_KEY}
SPRING_PROFILES_ACTIVE=local,observability

SERVER_PORT=8082
EOF

write_file "${ROOT}/whitelabel-notify-service/.env" <<EOF
EMAIL_PROVIDER=${EMAIL_PROVIDER:-mailjet}
MAILJET_API_KEY=${MAILJET_API_KEY:-}
MAILJET_SECRET_KEY=${MAILJET_SECRET_KEY:-}
EMAIL_FROM=${EMAIL_FROM}
EMAIL_FROM_NAME=${EMAIL_FROM_NAME:-${APP_NAME}}
INTERNAL_SERVICE_API_KEY=${INTERNAL_SERVICE_API_KEY}
SPRING_PROFILES_ACTIVE=local,observability

RESEND_API_KEY=${RESEND_API_KEY}
FIREBASE_CREDENTIALS_PATH=${FIREBASE_CREDENTIALS_PATH}
TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
TWILIO_FROM_NUMBER=${TWILIO_FROM_NUMBER}

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_notify
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

SERVER_PORT=8083
APP_NAME=${APP_NAME}
EOF

# --- Infra (opcional) ---
write_file "${ROOT}/whitelabel-infra/.env" <<EOF
AWS_REGION=${AWS_REGION}
TF_VAR_environment=${TF_VAR_environment}
TF_VAR_project_name=${TF_VAR_project_NAME:-${TF_VAR_project_name}}

CLIENTS_REPO=../whitelabel-clients
GATEWAY_REPO=../whitelabel-gateway
AUTH_SERVICE_REPO=../whitelabel-auth-service
CORE_SERVICE_REPO=../whitelabel-core-service
NOTIFY_SERVICE_REPO=../whitelabel-notify-service
EOF

echo ""
echo "Concluído. Valores derivados do Supabase:"
echo "  URL:    ${SUPABASE_URL}"
echo "  JWKS:   ${SUPABASE_JWKS_URL}"
echo "  Issuer: ${SUPABASE_ISSUER}"
echo ""
echo "Próximo passo: cd whitelabel-infra/docker && docker compose up -d"
