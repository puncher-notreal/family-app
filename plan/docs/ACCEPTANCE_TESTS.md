# Acceptance & security test matrix v0.1

| Test | Preconditions | Action | Expected |
|---|---|---|---|
| T01 | Новый email | Register → verify | Семья ещё не создана; нет доступа к детским API |
| T02 | Взрослый создал семью/ребёнка | Generate pairing code → ребёнок вводит | Сначала `pending` без session; после parent approval ребёнок активирован; code consumed |
| T03 | Pairing code использован/истёк | Повторный ввод | Ошибка без выдачи сессии; rate limit |
| T04 | Family A и Family B | Подменить чужой family/child ID в GET/PATCH | 403/404 без раскрытия данных |
| T05 | helper | GET `/children/:childId/mood/parent` | Запрещено |
| T06 | Child A | Попытка запросить дневник Child B | Запрещено |
| T07 | Child | POST оценка 5 | 201, child attribution в аудите |
| T08 | Child | PATCH/DELETE собственной оценки | 403, оценка без изменений |
| T09 | co_parent | PATCH оценку 5→4 | 200, diary_audit before/after |
| T10 | Child | Создать ДЗ и замечание в своём расписании | 201, видно родителю |
| T11 | Недельное повторяющееся задание | Worker запущен дважды | Одно occurrence на каждую дату |
| T12 | Активная задача | Отправить 1 фото + описание | submitted, родителю notification |
| T13 | Отправленный отчёт | Родитель request changes | open, feedback виден ребёнку, старое фото сохранено |
| T14 | Повторный отчёт | Два одновременных approve запроса | Один completed, одно начисление баллов |
| T15 | 20 points, item 30 | Redeem item | 422, баланс 20 |
| T16 | 50 points, item 30 | Два одновременных redeem | Баланс не отрицательный, максимум одна доступная покупка при 50 и цене 30 |
| T17 | Redeem requested | Parent decline дважды | Refund ровно один раз |
| T18 | Wish List ребёнка | Создать title без фото/URL | Сохранено |
| T19 | Wish List | Родитель fulfilled | Ребёнок видит выполненное желание |
| T20 | Ребёнок отправил mood score 3, комментарий | GET parent mood API | Только score/date; нет plaintext comment/emoji |
| T21 | Ребёнок mood saved once | Обновил mood в тот же день | Одна запись за день, одно push событие |
| T22 | День без настроения | Worker reminder | Нейтральный reminder без автоматической диагностики |
| T23 | Разрешённый parent | Открыть daily talk reminder | Нет сводки/комментариев ребёнка |
| T24 | RU/EN | Сменить язык в обеих ролях | Все статические строки переводятся; нет raw keys |
| T25 | Родитель | Запросил отмену child device | Refresh и API с revoked session не работают |
| T26 | Media из чужой семьи | GET signed URL | 403/404, без public bucket link |
| T27 | Обработка фото | Upload с EXIF/GPS | EXIF удалён перед постоянным сохранением |
| T28 | Клиент без push permission | Выполнил задачу | Бизнес-логика работает, in-app уведомление создано |
| T29 | Член семьи отозван | Использовал старый token | Нет доступа после revocation |
| T30 | Account deletion | Запрос → execute under policy | Доступ отозван, workflow отслеживаемый, удаление в рамках утверждённой retention policy |

## Definition of Done для каждой фичи
- Unit tests и integration tests с PostgreSQL test DB; отрицательные permission tests обязательны.
- Двухъязычные тексты + loading/empty/error/success states.
- API OpenAPI contract обновлён вместе с UI typed-client.
- Изменения БД сопровождаются миграцией и rollback/forward plan.
- Логи не содержат PIN/password/token/фото/приватных комментариев.
- Сборка Android и iOS проходит в CI; manual smoke на реальном устройстве перед beta.
- Никакой реальный ребёнок или семейное фото не используется в тестовом seed.
