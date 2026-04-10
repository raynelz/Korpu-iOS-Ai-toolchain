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
| `x-swiftlint-check` | Проверка кода на SwiftLint правила |
| `x-figma-to-code` | Конвертация Figma-дизайна в Swift-код |
| `x-palette-manager` | Работа с цветами, ассетами, тенями |
| `x-typography-manager` | Работа со шрифтами и типографикой |
| `x-neomorphic-buttons` | Неоморфные кнопки (ConfigurableNeomorphicButton) |
| `x-neomorphic-views` | Неоморфные контейнеры (KONeomorphicView) |
| `x-definition-of-done` | **Обязательно перед коммитом** — чеклист готовности задачи |
| `x-permission` | Добавление/использование системных permissions |
| `x-notification-key` | Добавление/использование AppNotificationKeys (межмодульные события) |
| `x-safe-commit` | Безопасный локальный коммит (без push) |
