# API Contract v0.1

**Base URL:** `/v1`. HTTPS. JSON. Access token in `Authorization: Bearer`. На POST/command запросах клиента — `Idempotency-Key: <UUID>` для устранения повторов. Контракты оформляются через OpenAPI (serverless API на Vercel) и генерируют typed client.

## Общие формы

```json
{"data":{},"meta":{}}
```

```json
{"error":{"code":"FORBIDDEN","message":"Action not allowed","requestId":"..."}}
```

Ошибки: `400 VALIDATION_ERROR`, `401 UNAUTHENTICATED`, `403 FORBIDDEN`, `404 NOT_FOUND`, `409 CONFLICT`, `410 EXPIRED`, `422 INVALID_STATE`, `429 RATE_LIMITED`.

## Auth / session

| Method | Route | Авторизация / действие |
|---|---|---|
| POST | `/auth/adult/register` | email/password, consent reference; send verification |
| POST | `/auth/adult/verify-email` | verify token |
| POST | `/auth/adult/login` | email/password → access + rotating refresh |
| POST | `/auth/adult/password-reset/request` | generic success; do not enumerate emails |
| POST | `/auth/adult/password-reset/confirm` | reset credential, revoke sessions |
| POST | `/auth/refresh` | refresh-token rotation, replay/reuse detection |
| POST | `/auth/logout` | revoke current session |
| POST | `/auth/child/pair` | 6 digits + device challenge; создаёт pending pairing request, **без session** |
| GET | `/auth/child/pair-status` | device-scoped pending request token; статус и session только после подтверждения |
| GET | `/me` | user type, allowed families, role, child identity if relevant |

## Family and children

| Method | Route | Access |
|---|---|---|
| POST | `/families` | adult authenticated |
| GET | `/families/:familyId` | member |
| POST | `/families/:familyId/children` | owner/co_parent with child-write |
| GET | `/families/:familyId/children` | member, filtered by explicit permission |
| PATCH | `/families/:familyId/children/:childId` | owner/co_parent |
| POST | `/families/:familyId/invitations` | owner; email, relation_label, permission_profile |
| POST | `/invitations/accept` | intended email + logged in adult |
| PATCH | `/families/:familyId/members/:memberId` | owner (no silent self-escalation) |
| DELETE | `/families/:familyId/members/:memberId` | owner; revoke active sessions/scopes |
| POST | `/children/:childId/pair-code` | owner/co_parent; reveal code **once** |
| GET | `/children/:childId/devices` | owner/co_parent |
| GET | `/children/:childId/pair-requests` | owner/co_parent; ожидающие запросы устройств |
| POST | `/children/:childId/pair-requests/:requestId/approve` | owner/co_parent; approve конкретное устройство |
| POST | `/children/:childId/pair-requests/:requestId/reject` | owner/co_parent; reject конкретное устройство |
| DELETE | `/children/:childId/devices/:deviceId` | owner/co_parent; revoke child session |

## School diary

| Method | Route | Access |
|---|---|---|
| GET/POST | `/children/:childId/subjects` | GET allowed; POST child or qualified parent |
| GET/PUT | `/children/:childId/schedule` | GET/PUT allowed child or qualified parent |
| GET | `/children/:childId/diary?from=YYYY-MM-DD&to=...` | child/qualified parent |
| POST/PATCH | `/children/:childId/lessons` / `/lessons/:lessonId` | child or qualified parent |
| POST | `/children/:childId/grades` | child own or qualified parent |
| PATCH/DELETE | `/children/:childId/grades/:gradeId` | **qualified parent only**; soft-delete |
| POST/PATCH | `/children/:childId/remarks` / `/remarks/:id` | child or qualified parent; record actor |
| GET | `/children/:childId/grades/analytics?from=&to=&subjectId=` | qualified parent; score counts/trends/means |

**POST grade DTO:**
```json
{"lessonId":"uuid","subjectId":"uuid","score":5,"scoredAt":"2026-11-05T13:00:00+03:00","note":"optional"}
```
API must derive child/family scope from auth and verify subject/lesson ownership; passing arbitrary IDs cannot bypass scope. Parent deletes require reason optional and diary_audit mandatory.

## Tasks and submissions

| Method | Route | Access |
|---|---|---|
| GET | `/children/:childId/tasks?date=&status=` | child/qualified parent |
| POST | `/children/:childId/tasks` | parent/helper with task-write |
| PATCH | `/tasks/:taskId` | creator if permission, owner/co_parent |
| GET | `/children/:childId/task-occurrences?from=&to=` | child/qualified parent |
| POST | `/task-occurrences/:id/submissions` | child only; description + media asset IDs |
| POST | `/task-submissions/:id/approve` | qualified adult; idempotent |
| POST | `/task-submissions/:id/request-changes` | qualified adult; feedback required |

`POST /tasks`: `title`, `description?`, `points` integer >=0, `schedule.type=once|daily|weekly`, `weekdays?`, `startDate`, `endDate?`, `dueTime?`.

Submission `description` nonblank, `photoIds` count 1..3, all photos belong to child and have server `READY` status. A requested-changes decision reopens occurrence, but original report remains immutable.

## Media

| Method | Route | Access |
|---|---|---|
| POST | `/media/upload-intent` | authenticated actor; purpose, file type and size; returns short-lived signed PUT or upload strategy |
| POST | `/media/:id/complete` | verify object exists, MIME, size, malware policy, owner/purpose |
| GET | `/media/:id/view-url` | require family/child permission; signed URL short expiration |
| DELETE | `/media/:id` | parent/owner as configured; refuse removal of evidence tied to pending report unless replaced |

## Points/shop

| Method | Route | Access |
|---|---|---|
| GET | `/children/:childId/points` | child/qualified adult; balance, history |
| GET | `/families/:familyId/shop-items` | family/child member with allowed scope |
| POST/PATCH | `/families/:familyId/shop-items`, `/shop-items/:id` | qualified adult |
| POST | `/shop-items/:id/redeem` | child; DB transaction, reserve points |
| GET | `/children/:childId/redemptions` | child/qualified adult |
| POST | `/redemptions/:id/approve` | qualified adult |
| POST | `/redemptions/:id/decline` | qualified adult; refund exactly once |
| POST | `/redemptions/:id/fulfill` | qualified adult; only after approval |

## Wishes, mood and achievements

| Method | Route | Access |
|---|---|---|
| GET/POST | `/children/:childId/wishes` | GET child/qualified adult; POST child only |
| PATCH | `/wishes/:id` | child edits own content; qualified adult only `fulfilled` transition |
| POST | `/children/:childId/mood` | child only; score 1..10, emoji, comment? |
| GET | `/children/:childId/mood/me?from=&to=` | child own; decrypted comment only here |
| GET | `/children/:childId/mood/parent?from=&to=` | owner/co_parent only; **score and dates ONLY**; no emoji/comment fields |
| GET/POST | `/children/:childId/achievements` | GET child/qualified adult; POST adult manual award only until TBD |

## Notifications and settings

| Method | Route | Access |
|---|---|---|
| GET/PATCH | `/me/preferences` | notification times/timezone/language |
| POST | `/me/devices` | register push token; no secret in logs |
| DELETE | `/me/devices/:id` | revoke token |
| GET/PATCH | `/me/notifications` / `/me/notifications/:id/read` | actor's own data only |
| POST | `/me/deletion-request` | own account; family deletion requires explicit owner confirmation |

## Дополнительные ограничения
- Client never sends `familyId` as a trusted ownership assertion; relationship is resolved server-side.
- Parent grade updates & ledger commands always audited; no direct SQL from mobile.
- File URLs are not persisted as publicly accessible strings in API payloads.
- API must not return `mood.comment_ciphertext`, plain comments, hashed PIN, password hash, tokens to any adult response.
- Comprehensive OpenAPI-generated types and compatibility tests before UI implementation.
