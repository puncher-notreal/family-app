# Agent-ready implementation roadmap v0.1

**Стратегия:** сначала архитектура и UX; затем реализация по небольшим независимым PR. В MVP нет 3D, AI, monetization, school API.

## Phase 0 — product & safety gate (до кода)

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P0-01 | — | Freeze decisions: прочитать PRD, составить ADR для допущений P01–P12 | `DECISIONS_AND_TBD.md` обновлён, все TODO классифицированы |
| P0-02 | P0-01 | Threat model и data flow map детей | Список потоков, стран, провайдеров, consent gates |
| P0-03 | P0-01 | Wireframes 2 интерфейсов и переходов | Все экраны из UI_SPEC с empty/error/loading |
| P0-04 | P0-03 | Design tokens + RU/EN glossary | Проверка переводов и доступности, стиль ребёнка placeholder до TBD |
| P0-05 | P0-02 | Правовой checkpoint по целевым рынкам (GDPR/COPPA) / Apple / Google Play | Протокол решения, без утверждений о compliance до проверки |
| P0-06 | P0-01 | API+DB schema review и ADR по permission profiles | Установлены владельцы данных, тесты IDOR специфицированы |

**Gate G0:** без утверждённых UX-потоков, матрицы прав и данных не переходить к production инфраструктуре.

## Phase 1 — repository and infrastructure

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P1-01 | G0 | monorepo pnpm: `apps/mobile`, `apps/api` (Vercel serverless), `packages/jobs` (cron), `packages/contracts` | `pnpm install`, lint/typecheck/test scripts запускаются |
| P1-02 | P1-01 | Expo Router mobile skeleton + two route groups | Android + iOS dev builds; auth guards |
| P1-03 | P1-01 | Serverless API on Vercel, Zod validation, OpenAPI, health endpoints | `GET /health` ответ на Vercel deploy, typed client генерируется |
| P1-04 | P1-03 | Supabase project + migrations + RLS policies + synthetic seed | Миграции на чистой БД/повторный deploy; RLS включён; без real PII |
| P1-05 | P1-03 | Supabase Storage private bucket, upload/download intent | Нельзя получить чужую ссылку, public access запрещён |
| P1-06 | P1-01 | CI checks + secret scan + integration DB | PR blocked on failing lint/typecheck/integration |

**Gate G1:** одна команда поднимает локальный API/DB/mobile, защищённые базовые шаблоны.

## Phase 2 — Identity and family

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P2-01 | G1 | Adult auth, verification, reset, refresh rotation | integration+brute-force tests |
| P2-02 | P2-01 | Family, owner, multiple children | infinite child product count; no cross-family access |
| P2-03 | P2-02 | Family invites + relation label + permission_profile | invited email only, revoke immediately effective |
| P2-04 | P2-02 | Child 6-digit pairing + parent confirmation and device session | TTL/attempt/replay test; parent revoke works |
| P2-05 | P2-03,P2-04 | Mobile onboarding / role routing | parent & child see isolated interfaces |
| P2-06 | P2-02 | Consent/version/age-aware data minimization | no child created before required consent gate |

**Gate G2:** 2 взрослых + 2 ребёнка в одной тестовой семье; ребёнок B не видит записи A.

## Phase 3 — diary

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P3-01 | G2 | Subjects + weekly schedule + date overrides | Date/slot uniqueness, timezone tests |
| P3-02 | P3-01 | Child and parent lesson editor: homework, notes, remarks | Both create/adjust permitted fields |
| P3-03 | P3-01 | Child grade INSERT + adult update/soft-delete + diary_audit | Child PATCH/DELETE grade 403, audit correct |
| P3-04 | P3-03 | Parent analytics: mean, distribution, trends, period filters | exact fixtures, no grade handling, deleted grades excluded |
| P3-05 | P3-02,P3-04 | Diary UI both roles with RU/EN | week/day layouts, empty, offline/connection states |

**Gate G3:** полная week diary demo с ребёнком и родителем.

## Phase 4 — tasks, reports & reward points

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P4-01 | G2 | Task creation one-off/daily/weekly; worker materializes occurrences | double worker execution no duplicate |
| P4-02 | P4-01,P1-05 | Child photo report + description; image scrub & metadata | 1–3 photo required, no EXIF in Storage |
| P4-03 | P4-02 | Adult approve / request changes with immutable history | no duplicate approvals, feedback visible |
| P4-04 | P4-03 | Point wallet + append-only ledger | 2 concurrent approve → one award; balance >=0 |
| P4-05 | P4-03,P4-04 | Adult/child task UI | task author/reviewer visible, all statuses supported |

**Gate G4:** actor A posts report; actor B approves; exactly one ledger event.

## Phase 5 — shop, wishes, simple achievements

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P5-01 | G4 | Adult creates family shop items | validation for positive price and family scope |
| P5-02 | P5-01 | Child redemption, reserve balance, adult approve/decline/fulfill | concurrent redemption & refund exactly once |
| P5-03 | G2,P1-05 | Child wishes and adult fulfilled marking | optional photo/url, no forced points link |
| P5-04 | G2 | Manual achievement award with placeholder badge | child sees award, fancy collection/automation **disabled** |
| P5-05 | P5-02,P5-03,P5-04 | UI shop/wishes/achievement list | full error/empty/positive states RU/EN |

**Gate G5:** child gets points from task, buys a parent-created reward, parent marks fulfilled.

## Phase 6 — mood, feed and notifications

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P6-01 | G2 | Mood save daily, encrypted comment, parent score-only endpoint | comment absent from parent API/logs, one daily record |
| P6-02 | P6-01 | Chart and mood forms RU/EN | 1–10, emoji, optional note, empty days handled |
| P6-03 | G2,P4-01 | Notification outbox, worker, push permissions, in-app center | duplicate event not sent twice; no sensitive payload |
| P6-04 | P6-03,P6-01 | Evening mood reminder + parent mood notification | one push/event per local day, timezone test |
| P6-05 | P6-03 | Adult daily conversation reminder, **no summary** | no child comments/grades in notification |
| P6-06 | G3,G4,G5,P6-01 | Adult/child day feed | only authorized events; pagination/sorting |

**Gate G6:** one end-to-end family day works on physical Android/iPhone.

## Phase 7 — release preparation

| Ticket | Depends | Deliverable | Acceptance |
|---|---|---|---|
| P7-01 | G6 | Account delete/child delete policy + UX + service workflow | tested retention, immediate session revoke |
| P7-02 | G6 | Security review / IDOR & threat model verification | all T01–T30 green, no exposed media |
| P7-03 | G6 | Production Supabase/Vercel setup, region выбор, backups, restore drill | DB+Storage recovery documented; secrets rotated; RLS verified in prod |
| P7-04 | G6 | Store disclosure, screenshots, permissions, legal signoff | legal gates passed, current Apple/Google policy reviewed |
| P7-05 | P7-01..04 | TestFlight + Google closed testing | critical bugs 0, crash-free gate defined |
| P7-06 | P7-05 | Gradual public release & monitoring | rollback/runbook and support channel exist |

## Cross-cutting agent rules
1. **One ticket per PR**, avoid «implement all». Keep migrations/API/client/UI/tests in one feature PR when necessary.
2. Every PR includes `summary`, affected data, privacy/security impact, exact commands run, screenshots/videos for UI, acceptance checklist.
3. Never assert pass without running checks. If environment lacks services, say exactly what could not be run.
4. Changes to parent/child privileges require an explicit tests update.
5. For TBD features implement only minimum compatible extension points; don't infer goals algorithms or badge art.
6. Write `ADR-xxx.md` when changing stack, data residency region, session model, or permission matrix.
7. Run unit + integration before moving to next ticket; human reviewer approves each gate.

## Пример порядка первых пяти задач агенту
`P0-01 → P0-03 → P0-04 → P0-06 → P1-01`. Перед реальными пользователями обязателен `P0-02/P0-05` и security gate; отсутствие правового заключения не маскировать результатами технических тестов.

## Примерный объём
Индивидуальная разработка с агентом: **ориентировочно 350–700 часов** включая QA, UX, backend/mobile, деплой. Не обещание срока; объём зависит от качества финального UI, решений TBD и правовых проверок целевых рынков. Продуктовые исследования/юридические услуги оплачиваются отдельно.
