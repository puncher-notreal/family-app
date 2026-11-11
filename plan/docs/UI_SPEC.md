# UI & Navigation specification v0.1

## Принципы
- Одна мобильная кодовая база, два route groups: `(adult)` и `(child)`; роль сервера определяет доступные экраны.
- Главная — **лента дня** (не абстрактный dashboard и не 3D).
- RU/EN с самого первого экрана; переключение без переустановки приложения. Все пользовательские даты/сроки через locale + timezone семьи.
- Детский визуальный стиль **TBD**. Пока строить нейтральный дизайн-токен-слой без окончательных иллюстраций и без 3D.

## Нижние вкладки взрослого — предлагаемый старт
1. `Сегодня` — дети, события дня, отчёты на проверку.
2. `Дневник` — переключение детей, неделя/день, оценки, аналитика.
3. `Задания` — шаблоны, повторы, отчёты, история.
4. `Магазин` — товары, заказы, баланс ребёнка, ручные достижения.
5. `Семья` — участники, дети, настроение (баллы/график), настройки, напоминания.

## Нижние вкладки ребёнка — предлагаемый старт
1. `Сегодня` — события дня, оценка настроения, ближайшие задания.
2. `Дневник` — расписание и записи.
3. `Задания` — активные и завершённые, фотоотчёты.
4. `Магазин` — товары, баланс, запросы.
5. `Моё` — желания, достижения, история настроения, настройки языка.

## Экранный реестр

| ID | Экран | Важные состояния |
|---|---|---|
| AUTH-01 | Выбор роли / Welcome | первый запуск, logout |
| AUTH-02 | Регистрация родителя | validation, policy/consent, email pending |
| AUTH-03 | Вход взрослого / reset password | invalid, rate limit, expired |
| AUTH-04 | Ввод 6 цифр ребёнком | invalid, expired, locked |
| P-01 | Лента взрослого | no children, one child, many children, no activity |
| P-02 | Добавить/редактировать ребёнка | consent, empty, save |
| P-03 | Участники семьи | invites, pending, revoke, relation label |
| P-04 | Подключить ребёнка | code countdown, used/expired, regenerate |
| P-05 | Дневник + аналитика | week/day, no grades, filtered subject |
| P-06 | Создать/редактировать задание | once/daily/weekly, repeat weekdays |
| P-07 | Проверка фотоотчёта | pending, approve, request changes, failed image |
| P-08 | Редактор товаров | active/inactive, price validation |
| P-09 | Запросы из магазина | requested/approved/fulfilled/declined |
| P-10 | История настроения | graph, missing days, score-only |
| P-11 | Настройки | language, timezone, push, conversation reminder |
| C-01 | Лента ребёнка | empty/today/overdue, notification action |
| C-02 | Дневник | grade add, homework, remark, parent edits info |
| C-03 | Карточка задания | submit photo + description, feedback, resend |
| C-04 | Магазин | insufficient points, requested, fulfilled |
| C-05 | Желания | create/edit own, fulfilled, optional media |
| C-06 | Отметить настроение | 1..10, emoji, comment, saved today |
| C-07 | Достижения | simple awarded list; expanded gallery TBD |
| SH-01 | Центр уведомлений | read/unread, type-safe detail link |
| SH-02 | Управление аккаунтом и удалением | confirmations, session revoked |

## Компоненты
`DayFeed`, `FamilyMemberChip`, `ChildSwitcher`, `SchoolWeekGrid`, `GradeChip`, `SubjectBadge`, `AssignmentCard`, `SubmissionPhotoPicker`, `ReviewControls`, `PointsBalance`, `ShopItemCard`, `WishCard`, `MoodRatingPicker`, `MoodTrendChart`, `NotificationItem`, `ConsentGate`.

## Доступность и детский UX
- Крупные touch targets, проверка screen-reader, contrast, dynamic font sizes, доступные состояния ошибок.
- Никакого публичного профиля ребёнка, рейтинга семей, стыда/красных предупреждений за низкие оценки, автоматических штрафов за настроение.
- Награды не должны превращать базовые потребности/общение в платную за баллы механику.
- Детский экран не должен показывать контакты/служебные email других родственников.
- Иконки всегда дублировать текстом для младших детей.

## Локализация
- Строки только из JSON переводов, включая errors, пуши, empty states, dates и accessibility labels.
- Языки `ru`, `en`; fallback русский, неизвестные ключи — ошибка CI.
- Пользовательские тексты (пожелания/задания) не переводятся автоматически.

## UI work items до начала реализации фич
1. User journey mapping для взрослого и ребёнка.
2. Wireframes всех основных экранов с пустыми/ошибочными состояниями.
3. 2–3 visual concepts для детского интерфейса; финальный стиль TBD.
4. UI kit (spacing/typography/colors/forms/cards/charts).
5. Интерактивный прототип регистрация → pairing → задание → отчёт → проверка → баллы → магазин.
