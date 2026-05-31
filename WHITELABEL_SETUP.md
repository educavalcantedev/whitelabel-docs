# Whitelabel Fullstack — Guia de Setup

> Guia legado de bootstrap e personalização de fork.  
> **Documentação canônica (atualizada):** [ARCHITECTURE.md](ARCHITECTURE.md) · env mestre: `.env.master` + `scripts/sync-env-from-master.sh`  
> Stack: React (Web) · React Native (Mobile) · Java Spring Boot (Backend) · Supabase (Auth)

**Modelo:** um fork = um deploy (Supabase + Postgres + env). **Não há multi-tenant** no código (`X-Tenant-ID`, tabela `tenants` e claim `tenant_id` foram removidos).

---

## Visão geral da arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│  Clientes                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  React Web   │  │ React Native │  │    Admin Panel       │  │
│  │  (Vite)      │  │ (Expo)       │  │    (React)           │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
└─────────┼────────────────┼──────────────────────┼──────────────┘
          │                │  autenticação         │
          └────────────────┼──────────────────────┘
                           ▼
                   ┌───────────────┐
                   │ Supabase Auth │  Email, OAuth, Magic Link
                   └───────┬───────┘
                           │ JWT
                           ▼
                   ┌───────────────┐
                   │  API Gateway  │  Spring Cloud Gateway
                   │  :8080        │  roteamento + rate limit
                   └──────┬────────┘
           ┌──────────────┼──────────────┐
           ▼              ▼              ▼
   ┌──────────────┐ ┌───────────┐ ┌──────────────────┐
   │ Auth Service │ │   Core    │ │    Notification  │
   │ :8084        │ │  Service  │ │    Service       │
   │              │ │  :8082    │ │    :8083         │
   └──────┬───────┘ └─────┬─────┘ └────────┬─────────┘
          │               │                │
          └───────────────┼────────────────┘
                          ▼
              ┌───────────────────────┐
              │  PostgreSQL  │  Redis │
              └───────────────────────┘
```

---

## Estrutura de repositórios — Opção 3 (Polyrepo por serviço)

Cada repositório tem seu próprio ciclo de release, pipeline de CI/CD e pode escalar
de forma independente. Os frontends ficam juntos por compartilharem componentes e tipos.

```
github.com/<org>/
├── whitelabel-docs           ← ARCHITECTURE.md, .env.master, scripts de sync
├── whitelabel-clients        ← monorepo: Web + Mobile + Admin
├── whitelabel-gateway        ← API Gateway (Spring Cloud Gateway)
├── whitelabel-auth-service   ← Auth Service (Spring Boot)
├── whitelabel-core-service   ← Core Service (Spring Boot)
├── whitelabel-notify-service ← Notification Service (Spring Boot)
└── whitelabel-infra          ← Docker Compose, Kubernetes, Terraform
```

### Como fazer o fork de um novo cliente

```bash
# Para cada repositório, fazer o fork individualmente
gh repo fork <org>/whitelabel-clients       --clone --remote
gh repo fork <org>/whitelabel-gateway       --clone --remote
gh repo fork <org>/whitelabel-auth-service  --clone --remote
gh repo fork <org>/whitelabel-core-service  --clone --remote
gh repo fork <org>/whitelabel-notify-service --clone --remote
gh repo fork <org>/whitelabel-infra         --clone --remote

# Ou usar o script de bootstrap incluso no whitelabel-infra
./scripts/bootstrap-fork.sh --org <sua-org> --client meu-cliente
```

> O script `bootstrap-fork.sh` faz o fork de todos os repos, configura os upstreams
> e cria o arquivo `.env` inicial de cada serviço automaticamente.

---

## Pré-requisitos

| Ferramenta     | Versão mínima | Uso                          |
|----------------|---------------|------------------------------|
| Node.js        | 20 LTS        | Web, Mobile, Admin, tooling  |
| pnpm           | 9+            | Package manager do clients   |
| Java (JDK)     | 21            | Todos os serviços backend    |
| Maven          | 3.9+          | Build dos serviços backend   |
| Docker         | 24+           | Infra local                  |
| Docker Compose | 2.24+         | Orquestração local           |
| Expo CLI       | latest        | React Native                 |
| Supabase CLI   | latest        | Auth e migrations            |

---

## Repositório 1 — `whitelabel-clients`

Monorepo com Turborepo. Web, Mobile e Admin compartilham componentes e tipos.

```
whitelabel-clients/
├── apps/
│   ├── web/                        ← React + Vite + TailwindCSS         :5173
│   ├── mobile/                     ← React Native + Expo
│   └── admin/                      ← React + Vite (painel administrativo) :5174
├── packages/
│   ├── ui/                         ← componentes compartilhados (web + admin)
│   ├── config/                     ← eslint, tsconfig, prettier base
│   └── shared-types/               ← tipos TypeScript compartilhados
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── .cursorrules
├── turbo.json
├── package.json                    ← pnpm workspaces root
└── README.md
```

### `apps/web/` — React Web

```
apps/web/
├── public/
│   └── logo.svg                    ← substituir pelo logo do cliente
├── src/
│   ├── components/
│   │   ├── ui/                     ← Button, Input, Card, Badge
│   │   └── layout/                 ← Header, Sidebar, PageWrapper
│   ├── features/
│   │   └── auth/
│   │       ├── LoginPage.tsx
│   │       ├── AuthCallback.tsx
│   │       └── useAuth.ts
│   ├── pages/
│   │   └── HomePage.tsx            ← tela inicial pós-login (placeholder)
│   ├── lib/
│   │   ├── supabase.ts             ← client Supabase configurado
│   │   └── api.ts                  ← axios com interceptor JWT
│   ├── hooks/
│   ├── theme/
│   │   └── tokens.ts               ← cores, tipografia, espaçamentos
│   └── router/
│       └── index.tsx               ← React Router com rota protegida
├── vite.config.ts
├── tailwind.config.ts
└── .env.example
```

#### Tela inicial (`HomePage.tsx`) — placeholder

```tsx
// src/pages/HomePage.tsx
import { useAuth } from '@/features/auth/useAuth'

export function HomePage() {
  const { user, signOut } = useAuth()

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6">
      <img src={import.meta.env.VITE_APP_LOGO_URL} alt="Logo" className="h-12" />
      <h1 className="text-2xl font-semibold">
        Bem-vindo, {user?.email}
      </h1>
      <p className="text-muted-foreground">
        Aplicação em construção — novas telas em breve.
      </p>
      <button onClick={signOut} className="btn-outline">
        Sair
      </button>
    </div>
  )
}
```

#### Variáveis de ambiente (`apps/web/.env.example`)

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=sb_publishable_<sua-chave>   # Project Settings → API Keys
VITE_API_GATEWAY_URL=http://localhost:8080
VITE_APP_NAME=Minha Aplicação
VITE_APP_LOGO_URL=/logo.svg
```

---

### `apps/mobile/` — React Native + Expo

```
apps/mobile/
├── assets/
│   └── logo.png                    ← substituir pelo logo do cliente
├── src/
│   ├── components/
│   │   └── ui/
│   ├── features/
│   │   └── auth/
│   │       ├── LoginScreen.tsx
│   │       └── useAuth.ts
│   ├── screens/
│   │   └── HomeScreen.tsx          ← tela inicial pós-login (placeholder)
│   ├── navigation/
│   │   └── RootNavigator.tsx       ← Stack com AuthStack e AppStack
│   ├── lib/
│   │   ├── supabase.ts
│   │   └── api.ts
│   └── theme/
│       └── tokens.ts
├── app.json                        ← name, slug, bundleIdentifier — personalizar aqui
├── app.config.ts
├── babel.config.js
└── .env.example
```

#### Tela inicial (`HomeScreen.tsx`) — placeholder

```tsx
// src/screens/HomeScreen.tsx
import { View, Text, Image, TouchableOpacity, StyleSheet } from 'react-native'
import { useAuth } from '@/features/auth/useAuth'

export function HomeScreen() {
  const { user, signOut } = useAuth()

  return (
    <View style={styles.container}>
      <Image source={require('@/assets/logo.png')} style={styles.logo} />
      <Text style={styles.title}>Bem-vindo, {user?.email}</Text>
      <Text style={styles.subtitle}>
        Aplicação em construção — novas telas em breve.
      </Text>
      <TouchableOpacity style={styles.button} onPress={signOut}>
        <Text style={styles.buttonText}>Sair</Text>
      </TouchableOpacity>
    </View>
  )
}

const styles = StyleSheet.create({
  container:  { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 16, padding: 24 },
  logo:       { width: 120, height: 48, resizeMode: 'contain' },
  title:      { fontSize: 20, fontWeight: '600' },
  subtitle:   { fontSize: 14, color: '#666', textAlign: 'center' },
  button:     { marginTop: 8, paddingHorizontal: 24, paddingVertical: 10, borderRadius: 8, borderWidth: 1, borderColor: '#ccc' },
  buttonText: { fontSize: 14 },
})
```

#### Variáveis de ambiente (`apps/mobile/.env.example`)

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=sb_publishable_<sua-chave>
API_GATEWAY_URL=http://localhost:8080
APP_NAME=Minha Aplicação
APP_VERSION=1.0.0
```

---

### `apps/admin/` — Painel administrativo

```
apps/admin/
├── public/
│   └── logo.svg
├── src/
│   ├── features/
│   │   ├── auth/
│   │   ├── users/                  ← gestão de usuários (superadmin)
│   │   └── features-flags/         ← feature flags do deploy (futuro)
│   ├── pages/
│   │   └── DashboardPage.tsx
│   └── lib/
│       ├── supabase.ts
│       └── api.ts
└── .env.example
```

#### Variáveis de ambiente (`apps/admin/.env.example`)

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=sb_publishable_<sua-chave>   # Project Settings → API Keys
VITE_API_GATEWAY_URL=http://localhost:8080
VITE_ADMIN_ROLE=admin                ← role exigida no JWT para acesso
```

---

## Repositório 2 — `whitelabel-gateway`

Ponto de entrada único de todas as requisições. Roteia para os serviços internos,
aplica rate limiting e propaga o JWT para autenticação downstream.

```
whitelabel-gateway/
├── src/main/
│   ├── java/com/whitelabel/gateway/
│   │   ├── GatewayApplication.java
│   │   ├── config/
│   │   │   ├── RouteConfig.java         ← definição das rotas
│   │   │   ├── RateLimitConfig.java     ← rate limiting por IP
│   │   │   └── CorsConfig.java
│   │   └── filter/
│   │       ├── CorrelationIdFilter.java ← X-Request-Id / X-Trace-Id
│   │       ├── JwtRelayFilter.java      ← propaga Authorization header
│   │       └── GatewayAccessLogFilter.java
│   └── resources/
│       └── application.yml
├── pom.xml
└── .env.example
```

### Tabela de rotas

| Prefixo            | Serviço destino          | Porta |
|--------------------|--------------------------|-------|
| `/auth/**`         | whitelabel-auth-service  | 8084  |
| `/v1/**`           | whitelabel-core-service  | 8082  |
| `/actuator/health` | próprio gateway          | 8080  |

> **Notify** não é exposto no gateway — apenas rede interna + `X-Internal-Api-Key`.

### Variáveis de ambiente (`.env.example`)

```env
AUTH_SERVICE_URL=http://localhost:8084
CORE_SERVICE_URL=http://localhost:8082

# JWT assimétrico (RS256) — projetos novos no Supabase (após out/2025)
SUPABASE_JWKS_URL=https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json
SUPABASE_ISSUER=https://<project-ref>.supabase.co/auth/v1

RATE_LIMIT_REQUESTS_PER_SECOND=50
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5174
```

---

## Repositório 3 — `whitelabel-auth-service`

Responsável por sincronizar a identidade do Supabase com o banco local e gerenciar
permissões dentro da aplicação. Não armazena senha — delega isso ao Supabase.

```
whitelabel-auth-service/
├── src/main/
│   ├── java/com/whitelabel/auth/
│   │   ├── AuthServiceApplication.java
│   │   ├── config/
│   │   │   ├── SecurityConfig.java
│   │   │   └── AppProperties.java
│   │   ├── security/
│   │   │   ├── JwtAuthFilter.java          ← valida JWT do Supabase
│   │   │   └── SupabaseJwtUtil.java
│   │   ├── domain/
│   │   │   └── identity/
│   │   │       ├── Identity.java           ← entidade JPA
│   │   │       ├── IdentityRepository.java
│   │   │       └── IdentityService.java    ← upsert ao primeiro login
│   │   └── api/
│   │       └── AuthController.java         ← POST /auth/sync, GET /auth/me
│   └── resources/
│       ├── application.yml
│       └── db/migration/
│           └── V1__create_identities.sql
├── pom.xml
└── .env.example
```

### Endpoints

| Método | Rota         | Descrição                                      |
|--------|--------------|------------------------------------------------|
| POST   | `/auth/sync` | Cria ou atualiza o registro local do usuário   |
| GET    | `/auth/me`   | Retorna identidade local pelo sub do JWT       |

### Variáveis de ambiente (`.env.example`)

```env
# JWT assimétrico (RS256) — projetos novos no Supabase (após out/2025)
SUPABASE_JWKS_URL=https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json
SUPABASE_ISSUER=https://<project-ref>.supabase.co/auth/v1

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_auth
DB_USERNAME=postgres
DB_PASSWORD=postgres

SERVER_PORT=8084
```

> A porta foi ajustada para **8084** para não conflitar com o Expo (8081) em dev local.

---

## Repositório 4 — `whitelabel-core-service`

Coração da aplicação: perfil, branding via env (`GET /v1/app/config`), feature flags
globais do deploy e auditoria admin. Novos domínios do produto são adicionados aqui após o fork.

```
whitelabel-core-service/
├── src/main/
│   ├── java/com/whitelabel/core/
│   │   ├── CoreServiceApplication.java
│   │   ├── config/
│   │   │   ├── SecurityConfig.java
│   │   │   ├── CorsConfig.java
│   │   │   └── AppProperties.java
│   │   ├── security/
│   │   │   ├── JwtAuthFilter.java
│   │   │   └── SupabaseJwtUtil.java
│   │   ├── domain/
│   │   │   ├── user/
│   │   │   │   ├── User.java
│   │   │   │   ├── UserRepository.java
│   │   │   │   └── UserService.java
│   │   │   └── feature/
│   │   │       ├── FeatureFlag.java
│   │   │       ├── FeatureFlagRepository.java
│   │   │       └── FeatureFlagService.java
│   │   ├── api/
│   │   │   ├── UserController.java         ← GET/PUT /v1/me
│   │   │   ├── AppConfigController.java    ← GET /v1/app/config (público)
│   │   │   ├── FeatureController.java      ← GET /v1/features
│   │   │   └── HealthController.java       ← GET /health
│   │   └── shared/
│   │       ├── exception/
│   │       │   └── GlobalExceptionHandler.java
│   │       └── dto/
│   │           └── ApiResponse.java
│   └── resources/
│       ├── application.yml
│       └── db/migration/
│           ├── V1__create_users.sql
│           ├── V3__create_feature_flags.sql
│           └── V8__remove_multitenant.sql   ← fork existente: drop tenants/tenant_id
├── pom.xml
└── .env.example
```

### Endpoints

| Método | Rota               | Autenticação | Descrição                        |
|--------|--------------------|--------------|----------------------------------|
| GET    | `/health`          | Pública      | Status do serviço                |
| GET    | `/v1/me`           | JWT          | Perfil do usuário logado         |
| PUT    | `/v1/me`           | JWT          | Atualiza perfil                  |
| GET    | `/v1/app/config`   | Pública      | Nome, logo, cor (env `APP_*`)    |
| GET    | `/v1/features`     | JWT          | Feature flags ativas do deploy   |

### Expandindo após o fork

Novos módulos de produto entram como novos packages em `domain/`:

```
domain/
├── user/         ← já vem no template
├── feature/      ← já vem no template
├── audit/        ← auditoria admin
├── order/        ← você adiciona para e-commerce
├── appointment/  ← você adiciona para agenda
└── product/      ← você adiciona para catálogo
```

### Variáveis de ambiente (`.env.example`)

```env
# JWT assimétrico (RS256) — projetos novos no Supabase (após out/2025)
SUPABASE_JWKS_URL=https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json
SUPABASE_ISSUER=https://<project-ref>.supabase.co/auth/v1

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_core
DB_USERNAME=postgres
DB_PASSWORD=postgres

REDIS_HOST=localhost
REDIS_PORT=6379

APP_NAME=Minha Aplicação
APP_LOGO_URL=/logo.svg
APP_PRIMARY_COLOR=#2563eb
SERVER_PORT=8082
```

---

## Repositório 5 — `whitelabel-notify-service`

Serviço isolado para envio de notificações (push, e-mail, SMS). Separado do core
para escalar independentemente em picos de envio e trocar provedores sem impacto.

```
whitelabel-notify-service/
├── src/main/
│   ├── java/com/whitelabel/notify/
│   │   ├── NotifyServiceApplication.java
│   │   ├── config/
│   │   │   └── AppProperties.java
│   │   ├── domain/
│   │   │   └── notification/
│   │   │       ├── Notification.java
│   │   │       ├── NotificationRepository.java
│   │   │       └── NotificationService.java
│   │   ├── provider/
│   │   │   ├── EmailProvider.java          ← interface
│   │   │   ├── PushProvider.java           ← interface
│   │   │   ├── SmsProvider.java            ← interface
│   │   │   └── impl/
│   │   │       ├── ResendEmailProvider.java
│   │   │       ├── FirebasePushProvider.java
│   │   │       └── TwilioSmsProvider.java
│   │   └── api/
│   │       └── NotificationController.java ← POST /notifications/send
│   └── resources/
│       ├── application.yml
│       └── db/migration/
│           └── V1__create_notifications.sql
├── pom.xml
└── .env.example
```

### Endpoints

| Método | Rota                  | Descrição                             |
|--------|-----------------------|---------------------------------------|
| POST   | `/notifications/send` | Envia notificação (push, email ou SMS)|
| GET    | `/notifications/:id`  | Status de uma notificação             |
| GET    | `/health`             | Status do serviço                     |

### Variáveis de ambiente (`.env.example`)

```env
# E-mail
RESEND_API_KEY=<resend-api-key>
EMAIL_FROM=noreply@seudominio.com

# Push
FIREBASE_CREDENTIALS_PATH=/secrets/firebase.json

# SMS (opcional)
TWILIO_ACCOUNT_SID=<sid>
TWILIO_AUTH_TOKEN=<token>
TWILIO_FROM_NUMBER=+1234567890

DB_URL=jdbc:postgresql://localhost:5432/whitelabel_notify
DB_USERNAME=postgres
DB_PASSWORD=postgres

SERVER_PORT=8083
```

---

## Repositório 6 — `whitelabel-infra`

Infraestrutura como código. Contém Docker Compose para dev local, manifests
Kubernetes para produção e Terraform para cloud.

```
whitelabel-infra/
├── docker/
│   ├── docker-compose.yml           ← todos os serviços para dev local
│   └── docker-compose.override.yml  ← overrides locais (não commitar)
├── k8s/
│   ├── base/                        ← manifests base (Kustomize)
│   │   ├── gateway/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── hpa.yaml             ← HorizontalPodAutoscaler
│   │   ├── auth-service/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── hpa.yaml
│   │   ├── core-service/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── hpa.yaml
│   │   └── notify-service/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── hpa.yaml
│   └── overlays/
│       ├── staging/
│       └── production/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
│       ├── eks/                     ← cluster Kubernetes (AWS)
│       ├── rds/                     ← PostgreSQL gerenciado
│       └── elasticache/             ← Redis gerenciado
├── scripts/
│   └── bootstrap-fork.sh            ← script de fork automático
└── README.md
```

### `docker-compose.yml` — dev local completo

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
    ports: ["5432:5432"]
    volumes: [postgres_data:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  gateway:
    build: ../whitelabel-gateway
    ports: ["8080:8080"]
    env_file: ../whitelabel-gateway/.env
    depends_on: [postgres, redis]

  auth-service:
    build: ../whitelabel-auth-service
    ports: ["8081:8081"]
    env_file: ../whitelabel-auth-service/.env
    depends_on: [postgres]

  core-service:
    build: ../whitelabel-core-service
    ports: ["8082:8082"]
    env_file: ../whitelabel-core-service/.env
    depends_on: [postgres, redis]

  notify-service:
    build: ../whitelabel-notify-service
    ports: ["8083:8083"]
    env_file: ../whitelabel-notify-service/.env
    depends_on: [postgres]

volumes:
  postgres_data:
```

### HPA — escalar pods individualmente

Cada serviço tem seu próprio `hpa.yaml`. Exemplo para o `core-service`:

```yaml
# k8s/base/core-service/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: core-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: core-service
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

O `notify-service` pode ter `maxReplicas: 50` enquanto o `auth-service` fica em 5 — cada um escala conforme sua carga real.

---

## Fluxo de autenticação completo

```
Frontend (Web / Mobile / Admin)
  │
  ├─ 1. Usuário submete credenciais
  ▼
Supabase Auth
  ├─ 2. Valida e retorna JWT RS256 (exp: 1h) + Refresh Token
  ▼
Frontend armazena JWT em memória / SecureStore (mobile)
  │
  ├─ 3. Requisição → Authorization: Bearer <jwt>
  ▼
API Gateway (:8080)
  ├─ 4. CorrelationIdFilter → gera/propaga X-Request-Id e X-Trace-Id
  ├─ 5. JwtRelayFilter → propaga Authorization para o serviço destino
  ├─ 6. Roteia para o serviço correto por prefixo de rota
  ▼
Serviço (Auth / Core / Notify interno)
  ├─ 7. JwtAuthFilter → busca chave pública no JWKS endpoint (cache local)
  ├─ 8. Verifica assinatura RS256 com a chave pública — sem chamar o Supabase
  ├─ 9. Valida issuer, expiração e claims
  ├─ 10. Extrai sub (UUID Supabase) para o contexto de segurança
  ├─ 11. Executa lógica de negócio
  ▼
PostgreSQL / Redis
```

> **JWT assimétrico (RS256):** o serviço busca a chave pública uma vez no endpoint JWKS
> e a armazena em cache. A validação de todas as requisições seguintes é feita localmente
> com essa chave — zero latência de rede na hot path. A chave é rotacionada automaticamente
> pelo Supabase; o cache do serviço se atualiza a cada hora.

---

## Implementação do JwtAuthFilter — RS256 (assimétrico)

Todos os serviços Java compartilham a mesma implementação. Adicionar as dependências
no `pom.xml` de cada serviço:

```xml
<!-- JWT + JWKS (auth0) -->
<dependency>
  <groupId>com.auth0</groupId>
  <artifactId>java-jwt</artifactId>
  <version>4.4.0</version>
</dependency>
<dependency>
  <groupId>com.auth0</groupId>
  <artifactId>jwks-rsa</artifactId>
  <version>0.22.1</version>
</dependency>
```

### `SupabaseJwtUtil.java`

```java
@Component
public class SupabaseJwtUtil {

    private final JwkProvider jwkProvider;
    private final String issuer;

    public SupabaseJwtUtil(
        @Value("${supabase.jwks-url}") String jwksUrl,
        @Value("${supabase.issuer}")   String issuer
    ) {
        this.issuer = issuer;
        // cache de 10 chaves, válido por 24h, máx 10 req/min ao endpoint JWKS
        this.jwkProvider = new JwkProviderBuilder(new URL(jwksUrl))
            .cached(10, 24, TimeUnit.HOURS)
            .rateLimited(10, 1, TimeUnit.MINUTES)
            .build();
    }

    public DecodedJWT verify(String token) {
        DecodedJWT decoded = JWT.decode(token);
        Jwk jwk = jwkProvider.get(decoded.getKeyId());          // busca pelo kid
        Algorithm algorithm = Algorithm.RSA256((RSAPublicKey) jwk.getPublicKey(), null);
        return JWT.require(algorithm)
            .withIssuer(issuer)
            .build()
            .verify(token);
    }

    public String extractSubject(DecodedJWT jwt) {
        return jwt.getSubject();   // UUID do usuário no Supabase
    }
}
```

### `JwtAuthFilter.java`

```java
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final SupabaseJwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain chain
    ) throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        try {
            String token = header.substring(7);
            DecodedJWT jwt = jwtUtil.verify(token);

            UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                jwtUtil.extractSubject(jwt), null, List.of()
            );
            auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (JWTVerificationException | JwkException e) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token inválido");
            return;
        }

        chain.doFilter(request, response);
    }
}
```

### `application.yml`

```yaml
supabase:
  jwks-url: ${SUPABASE_JWKS_URL}
  issuer:   ${SUPABASE_ISSUER}
```

---

## Portas locais — referência rápida

| Serviço              | Porta |
|----------------------|-------|
| React Web            | 5173  |
| Admin Panel          | 5174  |
| React Native (Expo)  | 8081  |
| API Gateway          | 8080  |
| Auth Service         | 8084  |
| Core Service         | 8082  |
| Notification Service | 8083  |
| PostgreSQL           | 5432  |
| Redis                | 6379  |

> Auth Service usa porta **8084** para não conflitar com o Expo (8081) em dev local.

---

## Como rodar tudo localmente

```bash
# 1. Clonar todos os repos na mesma pasta raiz
mkdir whitelabel && cd whitelabel
git clone https://github.com/<org>/whitelabel-clients
git clone https://github.com/<org>/whitelabel-gateway
git clone https://github.com/<org>/whitelabel-auth-service
git clone https://github.com/<org>/whitelabel-core-service
git clone https://github.com/<org>/whitelabel-notify-service
git clone https://github.com/<org>/whitelabel-infra

# 2. Copiar e preencher todos os .env
for dir in whitelabel-gateway whitelabel-auth-service whitelabel-core-service whitelabel-notify-service; do
  cp $dir/.env.example $dir/.env
done
cp whitelabel-clients/apps/web/.env.example     whitelabel-clients/apps/web/.env.local
cp whitelabel-clients/apps/mobile/.env.example  whitelabel-clients/apps/mobile/.env.local
cp whitelabel-clients/apps/admin/.env.example   whitelabel-clients/apps/admin/.env.local

# 3. Subir infraestrutura (PostgreSQL + Redis + todos os serviços Java)
cd whitelabel-infra/docker
docker compose up -d

# 4. Instalar dependências dos clientes e rodar
cd ../../whitelabel-clients
pnpm install
pnpm dev
```

### Scripts dos clientes

| Comando                          | O que faz                        |
|----------------------------------|----------------------------------|
| `pnpm dev`                       | Sobe web + mobile + admin        |
| `pnpm build`                     | Build de produção de todos       |
| `pnpm lint`                      | Lint em todos os workspaces      |
| `pnpm test`                      | Testes em todos os workspaces    |
| `pnpm --filter web dev`          | Sobe apenas o web                |
| `pnpm --filter mobile start`     | Sobe apenas o mobile (Expo)      |
| `pnpm --filter admin dev`        | Sobe apenas o admin              |

### Scripts da infra

| Comando                          | O que faz                        |
|----------------------------------|----------------------------------|
| `docker compose up -d`           | Sobe toda a infraestrutura local |
| `docker compose up -d postgres`  | Sobe apenas o banco              |
| `docker compose logs -f gateway` | Logs do gateway em tempo real    |
| `docker compose down`            | Para tudo                        |
| `docker compose down -v`         | Para tudo e apaga volumes        |

---

## Personalização após o fork — checklist

### Identidade visual

- [ ] Substituir `apps/web/public/logo.svg`
- [ ] Substituir `apps/mobile/assets/logo.png`
- [ ] Substituir `apps/admin/public/logo.svg`
- [ ] Editar `apps/web/src/theme/tokens.ts` — cor primária, secundária, fonte
- [ ] Editar `apps/mobile/src/theme/tokens.ts`
- [ ] Editar `apps/mobile/app.json` — `name`, `slug`, `bundleIdentifier`, `package`

### Supabase

- [ ] Criar projeto em [supabase.com](https://supabase.com)
- [ ] Copiar `Project URL` para os `.env` de todos os apps e serviços
- [ ] Copiar `sb_publishable_...` (anon key) para os `.env` dos clientes (web, mobile, admin)
- [ ] Montar `SUPABASE_JWKS_URL` e `SUPABASE_ISSUER` para os `.env` dos serviços Java
- [ ] Habilitar provedores OAuth desejados (Google, Apple) em Authentication → Providers
- [ ] Configurar Redirect URLs em Authentication → URL Configuration

### Banco de dados

- [ ] Renomear os bancos no `docker-compose.yml` (dev local)
- [ ] Ajustar `DB_URL` nos envs de staging e produção
- [ ] Rodar migrations: `docker compose exec core-service mvn flyway:migrate`

### Branding do fork (sem multi-tenant)

- [ ] Preencher `.env.master` em `whitelabel-docs` e rodar `./scripts/sync-env-from-master.sh`
- [ ] Definir `APP_NAME`, `APP_LOGO_URL`, `APP_PRIMARY_COLOR` (core + clients)
- [ ] Validar `GET http://localhost:8080/v1/app/config` (público)
- [ ] Ajustar `VITE_APP_NAME` / `APP_NAME` (mobile)

### Notificações

- [ ] Criar conta no [Resend](https://resend.com) e adicionar `RESEND_API_KEY`
- [ ] Configurar projeto Firebase e baixar `firebase.json` para `FIREBASE_CREDENTIALS_PATH`
- [ ] (Opcional) Configurar Twilio para SMS

---

## Receber atualizações do template original

Cada repositório tem seu próprio upstream. Para atualizar todos de uma vez:

```bash
# No whitelabel-infra há um script para isso
./scripts/sync-upstream.sh

# Ou manualmente em cada repo
git fetch upstream
git rebase upstream/main
git rebase --continue   # se houver conflitos
```

---

## Dicas para uso no Cursor

- Abra cada repositório como uma **janela separada** no Cursor — isso melhora o indexing.
- Use `@gateway`, `@core`, `@auth` nas perguntas para focar o contexto no serviço correto.
- O arquivo `.cursorrules` em cada repo instrui o AI sobre as convenções daquele serviço.
- Para gerar um novo domínio no core: *"crie o módulo `order` seguindo a estrutura de `domain/user`"*.
- Para adicionar uma nova rota no gateway: *"adicione rota `/catalog/**` apontando para `catalog-service:8084`"*.
