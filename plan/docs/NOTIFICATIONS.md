# Notifications & scheduling v0.1

## События и получатели

| Event | Получатель | Push (без чувствительных данных) | In-app |
|---|---|---|---|
| CHILD_PAIRED | owner/co_parent | «Устройство ребёнка подключено» | да |
| TASK_ASSIGNED | конкретный ребёнок | «У тебя новое задание» | да |
| TASK_SUBMITTED | взрослые с review permission | «Есть отчёт по заданию» | да |
| TASK_APPROVED | ребёнок | «Задание подтверждено!» | да |
| TASK_CHANGES_REQUESTED | ребёнок | «Проверь комментарий к заданию» | да |
| POINTS_REDEEM_REQUESTED | adults with shop-review permission | «Новый запрос в магазине» | да |
| POINTS_REDEEM_APPROVED/DECLINED/FULFILLED | ребёнок | нейтральное сообщение | да |
| MOOD_RECORDED | owner/co_parent | «Ребёнок отметил настроение — загляните в приложение» | да |
| CHILD_MOOD_REMINDER | ребёнок | «Как прошёл день?» | опционально |
| PARENT_TALK_REMINDER | owner/co_parent | «Самое время поговорить с ребёнком о его дне» | опционально |

## Периодичность
- Запрос настроения по умолчанию 20:00 локального timezone семьи; если сегодня уже сохранён score, повторное напоминание не посылать.
- Напоминание о разговоре по умолчанию 20:30 локально. Настройки отдельные у каждого взрослого, opt-out.
- Задачи-повторы создаются worker на горизонт 7–14 дней и `UPSERT ON CONFLICT DO NOTHING` по `(task_id, date)`.
- Daily scheduler работает по локальной дате, учитывает DST/timezones; событие получает уникальный dedupe key `talk:<userId>:<localDate>` или `mood:<childId>:<localDate>`.

## Техническая доставка
1. Модуль пишет `notifications` и `notification_outbox` **в одной транзакции с бизнес-событием**.
2. Worker берёт `pending` по `run_at`, lock с `SKIP LOCKED`, отправляет, фиксирует результат и retry policy.
3. Push payload содержит только neutral text и opaque notification id. Любые подробности загружаются после проверки auth.
4. Если push denied/offline/provider error — запись остаётся в in-app центре. Доставка push считается best-effort, бизнес-действие не откатывается.
5. Токены устройств ротация и инвалидирование при ошибках delivery; не логировать токены.

## Будущие возможности, выключены
Еженедельная сводка, AI suggestions, «риск-настроение», рейтинг ребёнка, маркетинговые уведомления, события от школ.
