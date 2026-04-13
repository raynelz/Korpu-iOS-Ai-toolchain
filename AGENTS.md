# AGENTS.md

Инструкции для AI-агентов при работе с кодом в этом репозитории. Детальные workflow — в скиллах (`.agents/skills/`).

## Project Overview

Multi-target iOS приложение для разных национальных рынков. Единая кодовая база в `Korpu/`, визуальные отличия — через target-separated Design System. Минимальный таргет: **iOS 18.0**.

**Таргеты:** Korpu, Khidi, Kamurj, Ko'prik, Kopir, Aura, Күпер. Сейчас функционал единый, в будущем — уникальные фичи по национальности.

## Build & Run

```bash
open Korpu.xcodeproj
xcodebuild -project Korpu.xcodeproj -scheme Korpu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
swiftlint lint --config .swiftlint.yml
./apollo-ios-cli generate --path apollo-codegen-config.json
./apollo-ios-cli fetch-schema --path apollo-codegen-config.json
python3 DesignSystem/tools/generate_color_assets.py
python3 DesignSystem/tools/generate_value_tokens.py
python3 DesignSystem/tools/generate_radius_tokens.py
python3 DesignSystem/tools/generate_typography_tokens.py
```

Тесты пока отсутствуют.

## Architecture

**UIKit — MVP. SwiftUI — MVVM внутри MVP-обёртки.** Entry point: `Korpu/App/MainModule.swift`.

- **MVP модули** (`Korpu/Modules/{Feature}/`): Module + Presenter + ViewController. Presenter владеет логикой, View только отображает. → скилл `x-mvp-module`
- **SwiftUI модули**: `BaseSUIModule` + `@Observable @MainActor` ViewModel (наследует `BaseVM`) + SwiftUI View с `@State var vm`. **Не использовать** `@Published` / `@StateObject` / `@ObservedObject`. → скилл `x-swiftui-module`
- **Router** (`Korpu/Router/`): `Route.swift` → `RouteRegistry.swift` → `Router.swift`. Навигация **только** через `module?.router`. → скилл `x-router-navigation`
- **DI**: `AppAssembly.swift` — ~70+ lazy сервисов. Инъекция через `RouteRegistry`. → скилл `x-service-layer`
- **Networking**: Apollo GraphQL через `SharedAPI` (SPM). Операции в `Korpu/API/`, сервисы-обёртки в `Korpu/Services/`. → скилл `x-service-layer`
- **Permissions**: `PermissionsManager` (`@Observable @MainActor`) в `Korpu/Managers/PermissionsManager/`. Проверка: `status.isGranted` / `status.canRequest`.
- **Notifications**: `AppNotificationKeys.swift` + async sequence. Не использовать `NotificationCenter.default.addObserver` напрямую.

## Design System

| Слой | Токен | Назначение |
|------|-------|------------|
| Цвета | `DSBaseVariables.shared.*` | Семантические цвета (`bg.primary`, `text.quindenary`) |
| Типографика | `DesignSystemTypography.*` | Стили текста (`buttonL`, `titleS`, `textBody1`) |
| Raw шрифты | `Typography.Primary/Secondary/Display` | Шрифтовые семейства по таргету |
| Spacing | `DesignSystemDimens.Base.val{N}` | Отступы, padding, gaps |
| Радиусы | `DesignSystemRadius.val{N}` | Corner radii |

**UIKit:** `DSBaseVariables.shared.text.primary.uiColor`
**SwiftUI:** `ds.text.primary.color` (где `let ds = DSBaseVariables.shared`)

**Deprecated** (не использовать в новом коде): `Palette.*`, `PaletteBase.*`, `NeomorphismButton`, `NeomorphismView`, `NeomorphicView`.

→ Аудит модуля на DS-соответствие: скилл `x-ds-audit`
→ Работа с цветами/ассетами: скилл `x-palette-manager`
→ Работа со шрифтами: скилл `x-typography-manager`
→ Figma → код: скилл `x-figma-to-code`

## Multi-Target Rules

- По умолчанию изменения для **обоих** таргетов, если пользователь не указал иное
- **Никогда** `#if KHIDI` / `#if KORPU` для стилизации — используй Design System
- Korpu-ассеты без префикса (`.backgroundMain`), Khidi — с префиксом (`.khidiBackgroundMain`)
- Target-файлы: `Korpu/Korpu/` и `Korpu/Khidi/`, модули: `KorpuModules/` и `KhidiModules/`

→ Подробности: скилл `x-palette-manager`

## SwiftLint

4 кастомных правила: `no_print_calls` (ERROR), `use_identifiers_for_uiimage_names` (ERROR), `no_navigationcontroller_push` (WARNING), `no_raw_color_init` (ERROR). Исключён: `Korpu/API`.

→ Подробности и маппинг замен: скилл `x-swiftlint-check`

## Key Dependencies

| Библиотека | Назначение |
|-----------|------------|
| Apollo iOS | GraphQL клиент |
| DSBaseVariables | Design System цвета (internal) |
| Yandex MapKit | Карты |
| Firebase | Push, аналитика, крашлитика |
| LiveKit | Звонки (WebRTC) |
| Sentry | Error tracking |
| Kingfisher | Загрузка изображений |
| SnapKit | Auto Layout DSL (UIKit) |
| YooKassa | Платежи (РФ) |
| StoreKit | In-App Purchases (вне РФ) |
| Lottie | Анимации |
| IQKeyboardManager | Клавиатура |

## File Organization

```
Korpu/
├── App/                    # AppDelegate, MainModule, AppAssembly
├── API/                    # .graphql операции (автогенерация → SharedAPI/)
├── Modules/                # Фичи (Feed, Dating, Calls, Stories, Maps, Wallet, ...)
├── Router/                 # Навигация (Route, RouteRegistry, Router)
├── Services/               # Сетевые и бизнес-сервисы
├── Managers/               # PermissionsManager, Media, Session, Push, ...
├── DesignSystem/           # Generated токены + DesignSystemTypography
├── Resources/{Target}/     # Target-specific ассеты, цвета, шрифты
├── Common/                 # Extensions, Utilities, Reusable Views, Keychain
├── Domain/                 # Domain модели
├── Components/             # Переиспользуемые UI компоненты
├── Helpers/                # Утилиты
└── Views/                  # KOButton, KOTextField и подобные DS компоненты
SharedAPI/                  # SPM-библиотека: GraphQL-схема + операции + сгенерированный Apollo код
DesignSystem/               # Figma токены (JSON) + Python генераторы
```

## Serena — семантическая навигация по коду

Serena — MCP-сервер с language server под капотом. Даёт семантические инструменты вместо grep/read по строкам. **Используй в приоритете перед Grep/Read**, когда работаешь с символами Swift.

### Инструменты Serena

| Инструмент | Когда использовать |
|-----------|-------------------|
| `mcp__serena__get_symbols_overview` | Обзор всех top-level символов файла (классы, функции, enum) — вместо чтения всего файла |
| `mcp__serena__find_symbol` | Найти символ по имени во всём проекте (класс, метод, enum case) |
| `mcp__serena__find_referencing_symbols` | Найти всех, кто использует данный символ — перед рефактором или удалением |
| `mcp__serena__replace_symbol_body` | Заменить тело метода/класса целиком — точнее чем Edit по строкам |
| `mcp__serena__insert_after_symbol` | Вставить код после символа (новый метод, extension) |
| `mcp__serena__insert_before_symbol` | Вставить код перед символом |
| `mcp__serena__rename_symbol` | Переименовать символ во всём проекте через LSP |
| `mcp__serena__safe_delete_symbol` | Безопасно удалить символ (проверяет отсутствие references) |
| `mcp__serena__write_memory` | Сохранить важный контекст о проекте (архитектурные решения, паттерны) |
| `mcp__serena__read_memory` | Прочитать сохранённый контекст |
| `mcp__serena__list_memories` | Посмотреть все сохранённые memories |

### Правила использования Serena

**DO:**
- Начинай исследование файла с `get_symbols_overview` — получаешь структуру без чтения всего файла
- Используй `find_symbol` вместо Grep когда ищешь Swift-символ (класс, protocol, func, enum)
- Перед рефактором всегда вызывай `find_referencing_symbols` — узнаешь scope изменений
- Используй `replace_symbol_body` для замены реализации метода — не ломает соседние символы
- Сохраняй важные архитектурные решения через `write_memory` — они переживут сессию

**DON'T:**
- Не читай целый файл если нужен только один метод — используй `find_symbol` с `include_body=true`
- Не используй Grep для поиска Swift-символов если Serena доступна

### Установка (один раз на проект)

```bash
# Зависимости: brew install uv node
task agents        # создаёт .serena/project.yml
task agents-claude # создаёт .mcp.json с Serena + XcodeBuildMCP
```

## Figma MCP — дизайн-контекст

Figma MCP читает дизайн напрямую из Figma Dev Mode. Используй когда пользователь скидывает ссылку на фрейм/флоу.

**Требует:** `FIGMA_API_KEY` в окружении (`export FIGMA_API_KEY=...` или в `.zshrc`).

| Инструмент | Когда использовать |
|-----------|-------------------|
| `get_design_context` | Получить цвета, типографику, отступы из фрейма → сравнить с DS |

**Рабочий флоу:** пользователь открывает фрейм в Figma → скидывает ссылку → агент вызывает `get_design_context` → сравнивает с `DSBaseVariables` → фиксит через скилл `x-figma-ds-audit`.

→ Полный флоу: скилл `x-figma-ds-audit`

## XcodeBuildMCP — симулятор и сборка

XcodeBuildMCP даёт прямой доступ к симулятору и Xcode без ручных скринов от пользователя.

| Инструмент | Когда использовать |
|-----------|-------------------|
| Скриншот симулятора | Проверить верстку после изменений — не ждать скрин от разработчика |
| Сборка проекта | Убедиться что код компилируется перед коммитом |
| UI автоматизация (тап, свайп) | Проверить интерактивное поведение (навигация, анимации) |
| Запуск тестов | Прогнать тесты прямо из агента |
| LLDB / дебаг | Инспектировать переменные при крашах |

**Рабочий флоу проверки UI:**
1. Внёс изменения → собери проект через XcodeBuildMCP
2. Сделай скриншот симулятора → сравни визуально с макетом (макет скидывает разработчик)
3. Если что-то не так — итерируй без ручного цикла

## Agents

| Агент | Когда запускать |
|-------|----------------|
| `x-auditor` | После написания фичи — аудит утечек памяти, DS, deprecated, архитектуры |

## Skills Reference

| Скилл | Когда использовать |
|-------|-------------------|
| `x-mvp-module` | Создание UIKit MVP модуля (KO-шаблон) |
| `x-swiftui-module` | Создание SwiftUI модуля (MVVM в MVP-обёртке) |
| `x-router-navigation` | Добавление route, настройка навигации |
| `x-bottom-sheet` | Создание bottom sheet |
| `x-service-layer` | Создание GraphQL/REST сервиса + регистрация в AppAssembly |
| `x-ds-audit` | Аудит модуля на соответствие Design System |
| `x-figma-ds-audit` | Figma-ссылка → проверка цветов/типографики → фикс через DS-токены |
| `x-swiftlint-check` | Проверка кода на SwiftLint правила |
| `x-palette-manager` | Работа с цветами, ассетами, тенями |
| `x-typography-manager` | Работа со шрифтами и типографикой |
| `x-neomorphic-buttons` | Неоморфные кнопки (ConfigurableNeomorphicButton) |
| `x-neomorphic-views` | Неоморфные контейнеры (KONeomorphicView) |
| `x-definition-of-done` | **Обязательно перед коммитом** — чеклист готовности задачи |
| `x-permission` | Добавление/использование системных permissions |
| `x-notification-key` | Добавление/использование AppNotificationKeys (межмодульные события) |
| `x-safe-commit` | Безопасный локальный коммит (без push) |
