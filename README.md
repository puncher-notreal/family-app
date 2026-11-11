# Family App — monorepo v0.1

Мобильное приложение (iOS/Android через Expo) + веб-версия и API на Vercel, данные в Supabase.

## Стек
- `apps/mobile` — Expo (SDK 58) + Expo Router + TypeScript. Нативный клиент iOS/Android; **веб-версия деплоится на Vercel**.
- `apps/api` — serverless API на Vercel (Hono + OpenAPI), локальный dev-сервер — только для разработки.
- `packages/config` — общие tsconfig/eslint.
- БД — Supabase (PostgreSQL), миграции в `apps/api/src/supabase/migrations`.

## Требования
- Node.js >= 22, pnpm >= 11 (`corepack enable`)
- Expo Go на телефоне для нативной разработки

## Локальная разработка (нативная версия)
```bash
pnpm install
pnpm dev:api      # локальный API на http://localhost:4000 (опционально)
pnpm dev:mobile   # Expo dev server; открывать в Expo Go (Android/iOS)
```
`apps/mobile/.env` (опционально): `EXPO_PUBLIC_API_URL=http://<ваш-IP>:4000` — адрес API для Expo Go. По умолчанию `http://localhost:4000`.

Локального веба нет: веб-версия собирается и работает **только на Vercel**.

## Проверки
```bash
pnpm typecheck          # strict TS во всех пакетах
pnpm db:schema-test     # применяет миграции к in-process Postgres (PGlite) — гейт корректности схемы
```

## Supabase (боевая БД)
1. Создать проект в Supabase (регион — под целевой рынок, зафиксировать ADR).
2. `apps/api/.env`: `DATABASE_URL=<connection string из Supabase>` (project settings → database, режим session/pooler).
3. Применить миграции: `pnpm db:migrate` (идемпотентно, журнал в `schema_migrations`).

## Деплой на Vercel
Два проекта из одного репозитория:

1. **API**: Root Directory = `apps/api`. В Environment Variables: `DATABASE_URL` (Supabase). Роуты: `/health`, `/openapi.json`, `/v1/*`.
2. **Web (мобильная веб-версия)**: Root Directory = `apps/mobile`. В Environment Variables: `EXPO_PUBLIC_API_URL=https://<api-project>.vercel.app`.

## Правила работы агента
См. `plan/AGENTS.md` — работать по тикетам из `plan/docs/IMPLEMENTATION_PLAN.md`, один ticket = один PR.
