# Whitelabel Docs

Documentação central e scripts de desenvolvimento do monorepo Whitelabel.

## Documentação principal

**[ARCHITECTURE.md](ARCHITECTURE.md)** — arquitetura, fluxos, portas, segurança, observabilidade e onde expandir o sistema.

Guia legado de setup inicial: [WHITELABEL_SETUP.md](WHITELABEL_SETUP.md).

## Layout local recomendado

Clone este repositório **junto** aos demais na mesma pasta pai:

```text
whitelabel/                      # pasta de trabalho (não é um único git)
├── whitelabel-docs/             # este repositório
├── whitelabel-gateway/
├── whitelabel-auth-service/
├── whitelabel-core-service/
├── whitelabel-notify-service/
├── whitelabel-clients/
├── whitelabel-infra/
└── secrets/                     # credenciais locais (não versionar)
```

## Repositórios

| Repositório | README |
|-------------|--------|
| [whitelabel-gateway](https://github.com/educavalcantedev/whitelabel-gateway) | [README](https://github.com/educavalcantedev/whitelabel-gateway/blob/main/README.md) |
| [whitelabel-auth-service](https://github.com/educavalcantedev/whitelabel-auth-service) | [README](https://github.com/educavalcantedev/whitelabel-auth-service/blob/main/README.md) |
| [whitelabel-core-service](https://github.com/educavalcantedev/whitelabel-core-service) | [README](https://github.com/educavalcantedev/whitelabel-core-service/blob/main/README.md) |
| [whitelabel-notify-service](https://github.com/educavalcantedev/whitelabel-notify-service) | [README](https://github.com/educavalcantedev/whitelabel-notify-service/blob/main/README.md) |
| [whitelabel-clients](https://github.com/educavalcantedev/whitelabel-clients) | [README](https://github.com/educavalcantedev/whitelabel-clients/blob/main/README.md) |
| [whitelabel-infra](https://github.com/educavalcantedev/whitelabel-infra) | [README](https://github.com/educavalcantedev/whitelabel-infra/blob/main/README.md) |

Apps (dentro de `whitelabel-clients`):

- [web](https://github.com/educavalcantedev/whitelabel-clients/blob/main/apps/web/README.md)
- [admin](https://github.com/educavalcantedev/whitelabel-clients/blob/main/apps/admin/README.md)
- [mobile](https://github.com/educavalcantedev/whitelabel-clients/blob/main/apps/mobile/README.md)

## Variáveis de ambiente (monorepo)

```bash
cd whitelabel-docs
cp .env.master.example .env.master
# edite .env.master (Supabase, chaves internas, etc.)

./scripts/sync-env-from-master.sh
```

O script gera `.env` / `.env.local` nos repositórios irmãos (`../whitelabel-gateway`, etc.).  
Para outro layout, defina `WHITELABEL_MONOREPO_ROOT` apontando para a pasta que contém todos os repos.

## Quick start (dev)

```bash
cd ../whitelabel-infra/docker && docker compose up -d
cd ../whitelabel-clients && pnpm install && pnpm dev
```

Gateway: http://localhost:8080 · Grafana: http://localhost:3000
