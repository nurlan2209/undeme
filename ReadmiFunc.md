# Undeme Frontend Report

Дата анализа: 2026-03-01  
Область: Flutter frontend (`/undeme`)

## 1) Краткое резюме

Frontend структурирован по гибридной схеме:
- экраны в `lib/screens`
- feature-модули в `lib/features/*`
- общие слои в `lib/core/*`
- дизайн-система в `lib/utils` и `lib/widgets`

Текущее состояние:
- Базовый production-функционал реализован (auth, SOS, AI chat, profile CRUD, сервисные номера, правовая библиотека).
- Архитектурный каркас clean-like есть (разделение UI/data/domain/core).
- Есть точки улучшения для стабильности и UX-консистентности (стейт-навигация, персистентность чатов, реализация поиска в legal).

---

## 2) Структура frontend

Корневой каталог приложения:
- `undeme/lib/main.dart` — bootstrap и выбор стартового экрана.
- `undeme/lib/screens/*` — основные экраны приложения.
- `undeme/lib/features/auth` — авторизация и сессия.
- `undeme/lib/features/profile` — доменные сущности и API профиля.
- `undeme/lib/features/sos` — SOS-домен, контроллер, offline-очередь.
- `undeme/lib/features/ai` — AI repository и экран чата.
- `undeme/lib/core` — config, http client, ошибки.
- `undeme/lib/widgets` — reusable UI-компоненты.
- `undeme/lib/utils` — цвета и текстовые стили.

---

## 3) Навигационная карта

Навигация построена без named routes, через `Navigator` и переключение индекса `BottomNavBar`.

Bottom tabs (`undeme/lib/widgets/bottom_nav_bar.dart`):
- `0` — SOS
- `1` — Қызметтер (Экстренные службы)
- `2` — AI чат
- `3` — Заң (Правовая библиотека)
- `4` — Профиль

Стартовый поток:
1. `main.dart` -> `_BootstrapScreen`
2. Проверка токена через `AuthRepository.isLoggedIn()`
3. Если токен есть -> `HomeScreen`
4. Если токена нет -> `AuthScreen`

---

## 4) Полный каталог страниц (путь + функция)

## 4.1 `undeme/lib/main.dart`

Что делает:
- Запускает `UndemeApp`.
- Инициализирует `MaterialApp`.
- Через `_BootstrapScreen` решает, показывать `HomeScreen` или `AuthScreen`.

Зависимости:
- `AuthRepository` для проверки сессии.

Роль:
- Точка входа и gatekeeper по авторизации.

---

## 4.2 `undeme/lib/screens/auth_screen.dart`

Что делает:
- Единый экран логина и регистрации (переключаемый режим `isLogin`).
- Валидирует форму на клиенте.
- Вызывает `AuthRepository.login/register`.
- При успехе делает `Navigator.pushReplacement` в `HomeScreen`.

Основные действия пользователя:
- Войти
- Зарегистрироваться
- Переключить режим auth

API/данные:
- `POST /auth/login`
- `POST /auth/register`

Состояния:
- `isLoading`
- ошибки через `SnackBar`

---

## 4.3 `undeme/lib/screens/home_screen.dart` (SOS экран)

Что делает:
- Это root-экран с bottom navigation.
- Для индексов 1/2/3/4 делегирует в соответствующие экраны.
- На индексе 0 показывает SOS UI.
- Управляет `SosController` (countdown, отправка, offline очередь).

SOS поведение:
- Long press -> countdown (4 сек)
- Можно отменить отправку
- При отправке отображается статус
- При ошибке доступна кнопка повторной отправки
- Если есть offline очередь, показывается warning-блок

API/данные:
- через `SosRepository`:
  - `POST /sos/trigger`
  - `POST /sos/retry`

---

## 4.4 `undeme/lib/screens/services_screen.dart`

Что делает:
- Показывает карточки экстренных служб.
- Позволяет звонить по `tel:` ссылке через `url_launcher`.

Номера:
- 103 (медицинская)
- 102 (полиция)
- 101 (пожарная)
- 112 (единый номер)

Данные:
- Полностью статический контент.

---

## 4.5 `undeme/lib/features/ai/presentation/ai_chat_screen.dart`

Что делает:
- UI чата с AI-консультантом по безопасности.
- Показывает дисклеймер.
- Имеет quick prompts (detention/medical/domestic violence).
- Отправляет сообщение через `AiRepository.sendMessage`.
- Отображает ответ или текст ошибки.

API/данные:
- `POST /ai/chat`
- `GET /ai/history` реализован в repository, но сейчас экран историю не подгружает.

Состояния:
- `_sending`
- локальный список сообщений в памяти экрана

---

## 4.6 `undeme/lib/screens/legal_screen.dart`

Что делает:
- Показывает каталог правовых тем.
- Фильтрация по категориям (`Барлығы`, `Полиция`, `Конституциялық құқықтар`, и т.д.).
- Поиск-строка присутствует визуально, но логика поиска не подключена.

Данные:
- Полностью статический список `legalTopics` внутри экрана.

Ограничения:
- Нет backend-подгрузки, нет детального экрана статьи.

---

## 4.7 `undeme/lib/screens/profile_screen.dart`

Что делает:
- Загружает профиль пользователя.
- Редактирует и сохраняет имя/телефон.
- Управляет SOS-настройками (switches).
- Полный CRUD экстренных контактов (добавить/изменить/удалить).
- Logout.
- Безопасное удаление аккаунта с подтверждением паролем.

API/данные:
- `GET /auth/profile`
- `PUT /auth/profile`
- `POST /auth/profile/contacts`
- `PUT /auth/profile/contacts/:contactId`
- `DELETE /auth/profile/contacts/:contactId`
- `DELETE /auth/profile/account`

UX:
- Есть empty state контактов.
- Ошибки показываются через `SnackBar`.
- Email read-only.

---

## 5) Технические слои и data-flow

## 5.1 Core layer

- `undeme/lib/core/config/app_config.dart`
  - `API_BASE_URL` через `--dart-define`.
  - Дефолт: `http://localhost:5002/api`.
- `undeme/lib/core/network/api_client.dart`
  - Единая HTTP-обертка для `GET/POST/PUT/DELETE`.
  - Автоподстановка Bearer token.
  - Timeout + унификация ошибок через `ApiException`.
- `undeme/lib/core/errors/api_exception.dart`
  - Стандартизированная ошибка API.

## 5.2 Auth layer

- `auth_local_data_source.dart`
  - Хранение токена в `flutter_secure_storage`.
- `auth_repository.dart`
  - login/register/logout/isLoggedIn.

## 5.3 SOS layer

- `sos_controller.dart`
  - state machine (`idle/countdown/sending/success/queuedOffline/error`)
  - геолокация (`geolocator`)
  - сеть (`connectivity_plus`)
  - вибрация (`vibration`)
  - retries
  - flush offline очереди
- `offline_sos_queue.dart`
  - Хранение отложенных SOS в `shared_preferences`.
- `sos_repository.dart`
  - API вызовы `/sos/*`.

## 5.4 Profile layer

- `profile_repository.dart`
  - API профиля и контактов.
- domain-модели:
  - `user_profile.dart`
  - `emergency_contact.dart`

## 5.5 AI layer

- `ai_repository.dart`
  - запросы в AI backend.
- `ai_chat_screen.dart`
  - UI и клиентская история текущей сессии.

---

## 6) Общие UI-компоненты

- `custom_text_field.dart` — унифицированные поля ввода.
- `custom_button.dart` — стандартная кнопка.
- `emergency_contact_card.dart` — карточка контакта с edit/remove.
- `bottom_nav_bar.dart` — нижняя навигация.
- `utils/colors.dart`, `utils/text_styles.dart` — дизайн токены.

---

## 7) Используемые frontend-зависимости

Ключевые пакеты:
- `http` — REST-запросы.
- `flutter_secure_storage` — безопасное хранение auth-токенов.
- `shared_preferences` — локальная очередь SOS (offline).
- `connectivity_plus` — отслеживание сети.
- `geolocator` — получение координат.
- `vibration` — haptic feedback SOS.
- `url_launcher` — звонки в экстренные службы.

---

## 8) Сильные стороны фронтенда

1. Реализован end-to-end поток SOS с offline-режимом и retries.
2. Есть разделение на слой UI и слой доступа к данным.
3. Сессия хранится безопасно (`flutter_secure_storage`).
4. Профиль доведен до практического CRUD-UX.
5. AI-экран имеет защитный дисклеймер и быстрые сценарии вопросов.

---

## 9) Текущие ограничения и техдолг

1. Навигация построена на условном `if` в `HomeScreen`, без централизованного роутера.
2. В `LegalScreen` поле поиска пока визуальное (без фильтрации текста).
3. `AiRepository.history()` не используется в UI (история не восстанавливается между сессиями).
4. Offline SOS хранится в `shared_preferences` (для чувствительных данных лучше encrypted storage).
5. В части экранов есть устаревшие `withOpacity` и lint-warning по style/perf (не блокирует работу, но требует косметического рефакторинга).
6. Нет явного global state менеджера (BLoC/Riverpod), state локален по экранам.

---

## 10) Риски UX/поведения

1. При частом переключении вкладок состояние некоторых экранов может пересоздаваться (из-за pattern возврата новых экранов в `HomeScreen`).
2. AI-чат без persisted history может выглядеть "потерянным" после перезапуска.
3. Legal-контент статический и не обновляется централизованно.

---

## 11) Рекомендации (приоритет)

P0 (релизный минимум):
1. Реализовать текстовый поиск в `LegalScreen`.
2. Подгрузка `AI history` в `AiChatScreen` при `initState`.
3. Добавить обработку пустого/частичного ответа AI на уровне UI (retry action).

P1:
1. Перевести навигацию на `go_router` или `Navigator 2.0`.
2. Вынести состояние в Riverpod/BLoC для SOS/AI/Profile.
3. Перенести offline SOS-очередь в защищенное хранилище.

P2:
1. Локализация (i18n) для всех экранов.
2. UI accessibility pass (контраст, screen readers, масштаб текста).
3. Виджет/интеграционные тесты для SOS и Profile CRUD.

---

## 12) Матрица страниц и готовности

| Страница | Путь | Статус | Назначение |
|---|---|---|---|
| App Bootstrap | `undeme/lib/main.dart` | Готово | Проверка сессии и выбор стартового экрана |
| Auth | `undeme/lib/screens/auth_screen.dart` | Готово | Логин/регистрация |
| SOS/Home | `undeme/lib/screens/home_screen.dart` | Готово (core), улучшать UX | SOS сценарий + таб-хаб |
| Emergency Services | `undeme/lib/screens/services_screen.dart` | Готово | Быстрые звонки 101/102/103/112 |
| AI Chat | `undeme/lib/features/ai/presentation/ai_chat_screen.dart` | Частично готово | AI-помощник, нужен persistence history |
| Legal Library | `undeme/lib/screens/legal_screen.dart` | Частично готово | Статическая правовая библиотека |
| Profile | `undeme/lib/screens/profile_screen.dart` | Готово | Профиль, настройки SOS, CRUD контактов, удаление аккаунта |

---

## 13) Вывод

Frontend Undeme находится в рабочем состоянии и покрывает ключевые продуктовые сценарии безопасности.  
Для production-качества на следующем шаге стоит закрыть 3 зоны: 
1) консистентная навигация/стейт,
2) доведение AI и legal до функциональной полноты,
3) hardening хранения чувствительных оффлайн-данных.
