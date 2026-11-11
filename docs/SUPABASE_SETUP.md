# Настройка Supabase вручную (без интеграции агента)

## 1. Получить connection string

1. Откройте https://supabase.com/dashboard → ваш проект.
2. **Settings → Database → Connection string → URI**.
3. Переключитесь на вкладку **Connection pooling** (важно для Vercel serverless).
4. Скопируйте строку вида:
   ```
   postgresql://postgres.<project-ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:6543/postgres
   ```
   - Порт **6543** (transaction mode) — правильный выбор для serverless.
   - Замените `<PASSWORD>` на пароль БД, заданный при создании проекта (заменяется и в опции «Reset database password», если забыли).
   - Не выбирайте порт 5432/54321 — прямые коннекты хуже работают с Vercel.

## 2. Прописать в локальный .env

1. Откройте файл `apps/api/.env` (уже создан, в git не попадает).
2. Вставьте строку в переменную:
   ```
   DATABASE_URL=postgresql://postgres.<project-ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:6543/postgres
   ```
3. Сохраните. Содержимое файла никому не показывайте и не коммитьте.

## 3. Применить миграции (на вашем компьютере)

```powershell
# из корня репозитория F:\Family App\family-app
pnpm install            # если ещё не делали
pnpm db:migrate
```

Ожидаемый вывод:
```
applied 0001_init.sql
migrations done
```

Скрипт идемпотентный: повторный запуск пишет `skip 0001_init.sql (already applied)`.
Журнал применённых миграций — таблица `schema_migrations` в самой БД.

## 4. Проверить результат

В Supabase Dashboard:
- **Table Editor** — должно быть 36 таблиц (`users`, `families`, `children`, `school_grades`, `point_ledger`, `mood_entries`, `notification_outbox` и др.).
- В `schema_migrations` — одна строка `0001_init.sql`.

Альтернативная локальная проверка:
```powershell
pnpm db:migrate   # второй запуск: "skip ... already applied"
```

## 5. Vercel: два проекта

Интеграция Supabase (Vercel → Integrations) уже проставила `POSTGRES_URL` и ключи в проект `family-app`. Код API сам подхватит их: он использует `DATABASE_URL`, иначе fallback на `POSTGRES_PRISMA_URL` / `POSTGRES_URL` из интеграции. Настраивать вручную ничего не нужно — только Root Directory.

### 5.1. Проект API (существующий `family-app`)
1. Vercel → проект `family-app` → **Settings → General → Root Directory & Monorepo Handling** → Root Directory = `apps/api` → Save.
2. Сделайте **Deployments → последняя → Redeploy**.

### 5.2. Проект Web (новый)
1. Vercel → **Add New → Project** → Import GitHub-репо `puncher-notreal/family-app`.
2. Root Directory = `apps/mobile`. Имя проекта: `family-app-web` → Deploy.
3. **Settings → Environment Variables**: `EXPO_PUBLIC_API_URL` = URL API-проекта (виден в домене `family-app-...vercel.app` или в Production deployment), Environments: Production+Preview → Redeploy.
4. (Опционально) в API-проекте после первого деплоя веба ничего менять не нужно.

### 5.3. Если миграции на проде
Миграции применяются с локальной машины (шаг 3) — на Vercel автоматом они не гоняются. Новые миграции: добавить файл в `apps/api/src/supabase/migrations/` и локально выполнить `pnpm db:migrate` против `DATABASE_URL`.

## 6. Рекомендации по безопасности Supabase

- **Никогда** не вставляйте `service_role` ключ в мобильное приложение или репозиторий. Наше приложение ходит в Supabase только через собственный API на Vercel — anon/service ключи в клиенте не нужны.
- RLS: черновая схема пока без политик — они добавятся отдельной миграцией (второй слой защиты; первичный слой — авторизация в API). До этого единственный путь к данным — serverless API.
- Storage: все buckets должны быть **private**; публичный доступ не включать.
- Region проекта выбирать под целевой рынок (data residency) и зафиксировать ADR-ом.
- Бэкапы: включите Periodic backups или Point-in-Time Recovery, как только появятся реальные данные (Settings → Database → Backups).
- Токен Supabase CLI (если делали `supabase login`) хранится локально; отозвать можно на https://supabase.com/dashboard/account/tokens

## 7. Если что-то не работает

| Симптом | Причина / решение |
|---|---|
| `password authentication failed` | Неверный пароль в строке. Reset в Settings → Database → Database password |
| `Tenant or user not found` | Неверный `<project-ref>` в хосте; перепроверьте строку |
| `relation "users" already exists` | Миграции уже применены; смотрите `schema_migrations` |
| Миграция прошла, таблиц нет | Проверьте, что DATABASE_URL указывает на нужный Supabase-проект |
| Vercel API падает с «Missing database connection string» | Интеграционные переменные не привязаны к проекту; проверьте Integrations → Supabase → какой проект получает переменные, или добавьте `DATABASE_URL` вручную |
| Vercel-деплой падает на подключении | Убедитесь, что используете pooler (порт 6543), а не прямой порт 5432 |
