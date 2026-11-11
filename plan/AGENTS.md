# Instructions for coding agents — Family App v0.1

Ты — инженер-разработчик в репозитории мобильного приложения для родителей и детей 7–12 лет. Работай строго по файлам в `docs/`. **Не реализуй весь проект за одну итерацию.**

## Platform (fixed stack)
- **Backend + API:** Vercel (serverless, TypeScript). Все API endpoints разворачиваются только на Vercel; никаких отдельных самописных серверов.
- **БД:** Supabase (managed PostgreSQL). Все постоянные данные — только в Supabase; никаких самодельных файловых хранилищ и вторых БД.
- **Файлы/фото:** Supabase Storage (private bucket), доступ только через short-lived signed URLs.
- **Фоновые задачи:** Vercel Cron Jobs / serverless-очереди; никаких долгоживущих процессов вне Vercel.

## Before every change
1. Прочитай `README.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/DECISIONS_AND_TBD.md`.
2. Для затрагиваемого модуля прочитай `docs/ARCHITECTURE.md`, `docs/DATABASE_DESIGN.md`, `docs/API_CONTRACT.md`, `docs/SECURITY_PRIVACY.md`, `docs/ACCEPTANCE_TESTS.md`.
3. Найди конкретный ticket в `docs/IMPLEMENTATION_PLAN.md` и перечисли acceptance criteria.
4. Проверь, что тикет не требует решений из `TBD`. Если требует — не выдумывай; создай блокер и предложи безопасный, минимальный дизайн как ADR на утверждение.

## Constraints — must not violate
- Privacy-first и международный рынок: обработка данных строится так, чтобы соответствовать требованиям целевых юрисдикций (минимум: GDPR для ЕС, COPPA и Apple/Google Families policies для US). Правовые проверки конкретного рынка — отдельная задача владельца продукта, не агента.
- Никакой передачи данных детей третьим сторонам и стороннего AI-анализа детских эмоций в MVP.
- Никаких лишних сторонних SDK аналитики/рекламы. Никакой публикации или логирования идентифицирующих детей данных.
- PIN ребёнка — только ограниченный по TTL и попыткам одноразовый pairing code, а не самостоятельный постоянный пароль. Подключение нового устройства требует подтверждения взрослым.
- Grade: child = CREATE only; qualified adult = CREATE/UPDATE/SOFT DELETE с аудитом.
- Mood: adult получает score и дату, но **никогда** комментарий; UI должен объяснять privacy.
- Деньги и покупки в реальном мире не входят в scope; магазин только за виртуальные баллы.
- Ledger points append-only, идемпотентный, balance >= 0; любые изменения в транзакции.
- Все записи проверяются на scope `family/child`, не доверяй ID из request без серверной проверки. В Supabase все таблицы с детскими/семейными данными обязаны иметь включённый RLS; service-role key используется только на сервере (Vercel), никогда в клиенте.
- Никаких глобальных административных обходов в публичных endpoints.
- Отложенные функции TBD-GOALS, TBD-BADGES и финальный CHILD-UI не реализовывать без решения владельца продукта.

## Code quality
- TypeScript strict. Без `any` без комментария/обоснования. Type-safe request+response из OpenAPI.
- DTO validation server-side, centralized error codes, request-id/structured logs с PII redaction.
- PostgreSQL migrations versioned (Supabase migrations), never mutate applied migrations; expand/contract для изменения схемы.
- У каждой новой фичи есть unit + integration + permission-negative tests, RU/EN UI, пустые и ошибочные состояния.
- Для фото — private Supabase Storage bucket, ограничение размера/MIME, strip EXIF, short-lived signed URLs.
- Не добавляй платные зависимости, новые провайдеры/SDK, облачные сервисы или сторонние API без отдельного ADR и approval. Провайдеры Supabase и Vercel уже утверждены — всё остальное требует ADR.

## Execution / reporting format
```
Ticket: Pn-xx
Summary: ...
Changed files: ...
DB/API changes: ...
Security/privacy impact: ...
Tests run (commands + results): ...
Manual verification: ...
Unresolved/TBD: ...
Next ticket: ...
```

Не заявляй, что сборка работоспособна на устройстве, пока она не была реально собрана и проверена. Не использовать настоящие семейные данные в demo fixtures. Не проводить production deploy, не отправлять реальные push/e-mail и не менять настоящие базы (даже Supabase staging) без явного разрешения.
