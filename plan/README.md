# Семейное приложение — пакет проектирования v0.1

**Дата:** 05.11.2026  
**Статус:** архитектурная спецификация для старта разработки агентом; не готовый код продукта.  
**Рынок:** международный (privacy-first); интерфейс RU/EN. **Аудитория:** дети 7–12 лет. **Платформы:** iOS/Android.  
**Приоритет:** безопасность детей, простота, прозрачность логики, живое общение родителей и детей.

## С чего начать

1. Прочитать `docs/PRODUCT_REQUIREMENTS.md` и `docs/DECISIONS_AND_TBD.md`.
2. Прочитать `docs/SECURITY_PRIVACY.md` **до** разработки авторизации или хранения данных детей.
3. Ознакомиться с `docs/ARCHITECTURE.md`, `docs/DATABASE_DESIGN.md` и `db/001_schema_draft.sql`.
4. Использовать `AGENTS.md` как постоянные инструкции coding-агенту, а `agent_tasks/01_START_PROMPT.md` — как первое задание.
5. Реализовывать этапы из `docs/IMPLEMENTATION_PLAN.md` строго по порядку с проверкой критериев приёмки.

## Состав пакета

| Файл | Назначение |
|---|---|
| `docs/PRODUCT_REQUIREMENTS.md` | Зафиксированные ответы и функциональные требования |
| `docs/USER_FLOWS.md` | Сквозные сценарии, состояния и исключения |
| `docs/UI_SPEC.md` | Навигация, экраны, доступность, локализация |
| `docs/ARCHITECTURE.md` | Стек, границы компонентов, структура монорепозитория |
| `docs/DATABASE_DESIGN.md` | Сущности, индексы, целостность и бизнес-инварианты |
| `db/001_schema_draft.sql` | Предварительная исполнимая SQL-схема; **ревью перед production** |
| `docs/API_CONTRACT.md` | REST endpoints, DTO и коды ошибок |
| `docs/SECURITY_PRIVACY.md` | Threat model, детская приватность, правовые проверки, хранение |
| `docs/NOTIFICATIONS.md` | Push/in-app события, графики, идемпотентность |
| `docs/IMPLEMENTATION_PLAN.md` | Задачи для агента, зависимости, Definition of Done |
| `docs/ACCEPTANCE_TESTS.md` | Матрица E2E/автоматических тестов |
| `docs/DECISIONS_AND_TBD.md` | Что решено и что требует согласования |
| `AGENTS.md` | Правила работы ИИ-агента |
| `agent_tasks/01_START_PROMPT.md` | Первая рабочая инструкция агенту |

## Границы MVP

**Включено:** семья и несколько взрослых, несколько детей, безопасная активация ребёнка кодом, лента дня, школьный дневник, разовые и повторяющиеся задания, фотоотчёты и проверка, баллы, семейный магазин, желания, ежедневное настроение, история оценок настроения для родителя, уведомления, RU/EN, управление устройствами, удаление данных, журнал критических изменений.

**Ограниченный MVP:** ручное награждение ребёнка достижением без финального дизайна коллекций. **За feature flag:** цели и развитая система достижений до утверждения TBD.

**Не включено:** ИИ-опросник/ИИ-рекомендации, интеграции со школьными электронными системами, денежные переводы, семейный чат, семейный календарь, платные подписки, 3D, сложная геймификация.

## Техническая позиция

- Мобильное приложение: React Native + Expo Router + TypeScript.
- Backend: serverless API на **Vercel** (TypeScript, OpenAPI).
- Данные: **Supabase** — managed PostgreSQL (обязательный RLS) + private Storage для фото.
- Авторизация: взрослый — email/password; ребёнок — одноразовый шестизначный pairing-code, затем device-bound session.
- Фоновая обработка: Vercel Cron Jobs + serverless-очередь доставки событий (outbox в PostgreSQL).
- UI: адаптация под две роли в **одном** мобильном приложении.

> Важно: для целевых рынков необходимо проверить правовые основания обработки данных несовершеннолетних (например GDPR для ЕС, COPPA для US), региональные требования к хранению данных, статус Apple Kids Category и условия провайдеров (Vercel/Supabase) **до публичного запуска**.

## Ссылки на проверенную документацию

- GDPR (дети и согласие): https://gdpr.eu/
- COPPA: https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy
- Apple App Review: https://developer.apple.com/app-store/review/guidelines/
- Apple Kids: https://developer.apple.com/kids/
- Google Play Families: https://support.google.com/googleplay/android-developer/answer/9893335?hl=en
- Expo Router: https://docs.expo.dev/router/introduction/
- Expo EAS builds: https://docs.expo.dev/deploy/build-project/
- Expo push: https://docs.expo.dev/push-notifications/push-notifications-setup/
- Supabase: https://supabase.com/docs
- Supabase Row Level Security: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage: https://supabase.com/docs/guides/storage
- Vercel: https://vercel.com/docs
- Vercel Cron Jobs: https://vercel.com/docs/cron-jobs
