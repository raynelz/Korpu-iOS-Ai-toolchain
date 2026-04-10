---
name: x-swiftlint-check
description: Проверь код на соответствие SwiftLint правилам проекта Korpu перед коммитом или после написания кода. Используй при ревью кода, перед коммитом, или когда пользователь просит проверить код на lint-ошибки. Триггер — пользователь просит проверить код, сделать lint, или перед финализацией изменений.
---

# SwiftLint Checker

Проверь код на соответствие 4 кастомным SwiftLint правилам проекта Korpu.

## Конфигурация

Файл: `.swiftlint.yml`
Исключено из линтинга: `Korpu/API` (автогенерированный Apollo код)
Режим: `only_rules` — работают ТОЛЬКО 4 кастомных правила.

## 4 правила

### 1. no_print_calls (ERROR)

**Scope:** `Korpu/`
**Запрещено:** `print(...)`, `print ("...")`
**Правильно:** `Logger.log(level:, "...")`

```swift
// ❌ ERROR
print("User loaded")
print("Error: \(error)")

// ✅ Правильно
Logger.log(level: .info, "User loaded")
Logger.log(level: .error, "Error: \(error)")
```

### 2. use_identifiers_for_uiimage_names (ERROR)

**Scope:** `Korpu/`
**Запрещено:** `UIImage(named: "stringName")`
**Правильно:** `UIImage(resource: .iconName)`

```swift
// ❌ ERROR
let icon = UIImage(named: "settingsIcon")
imageView.image = UIImage(named: "avatar_placeholder")

// ✅ Правильно
let icon = UIImage(resource: .settingsIcon)
imageView.image = UIImage(resource: .avatarPlaceholder)
```

### 3. no_navigationcontroller_push (WARNING)

**Scope:** `Korpu/Modules/`
**Запрещено:** прямой push через navigationController
**Правильно:** навигация через `module?.router`

```swift
// ❌ WARNING
navigationController?.pushViewController(vc, animated: true)
self.navigationController?.push(vc)
navController?.pushViewController(detailVC, animated: true)

// ✅ Правильно (из Presenter)
module?.router.push(route: .detail(itemId))

// ✅ Правильно (из SwiftUI ViewModel)
router.push(route: .detail(itemId))
```

### 4. no_raw_color_init (ERROR)

**Scope:** `Korpu/`
**Запрещено:** `UIColor(rgb:)`, `UIColor(hex:)`, `.init(rgb:)`, `.init(hex:)`, `#colorLiteral`
**Правильно:** `Palette.*`, `UIColor(resource:)`, `DSBaseVariables.shared.*`

```swift
// ❌ ERROR
view.backgroundColor = UIColor(rgb: 0xFFFFFF)
label.textColor = UIColor(hex: "#333333")
let color = #colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)

// ✅ Правильно
view.backgroundColor = DSBaseVariables.shared.bg.primary.uiColor
label.textColor = Palette.Text.primary
let color = UIColor(resource: .backgroundMain)
```

## Процедура проверки

### Перед написанием кода

Помни 4 правила и пиши код с их учётом сразу.

### После написания кода

Проверь каждый изменённый файл на соответствие:

1. **Поиск print():** Найди все `print(` в изменённых файлах → замени на `Logger.log()`
2. **Поиск UIImage(named:):** Найди `UIImage(named:` → замени на `UIImage(resource:)`
3. **Поиск прямой навигации:** В файлах `Korpu/Modules/` найди `navigationController?.push` или `navController?.push` → замени на `module?.router.push(route:)`
4. **Поиск raw color init:** Найди `UIColor(rgb:`, `UIColor(hex:`, `#colorLiteral` → замени на Palette/DSBaseVariables/UIColor(resource:)

### Запуск линтера

```bash
swiftlint lint --config .swiftlint.yml
```

Или для конкретного файла:
```bash
swiftlint lint --config .swiftlint.yml --path Korpu/Modules/MyFeature/
```

## Быстрые замены

| Нарушение | Замена |
|-----------|--------|
| `print("msg")` | `Logger.log(level: .info, "msg")` |
| `print("Error: \(e)")` | `Logger.log(level: .error, "Error: \(e)")` |
| `UIImage(named: "icon")` | `UIImage(resource: .icon)` |
| `UIColor(rgb: 0xFF0000)` | `UIColor(resource: .colorName)` или `Palette.Something.color` |
| `UIColor(hex: "#FFF")` | `DSBaseVariables.shared.bg.primary.uiColor` |
| `#colorLiteral(...)` | `Palette.Component.propertyName` |
| `navController?.pushViewController(vc)` | `module?.router.push(route: .routeName)` |

## Logger уровни

```swift
Logger.log(level: .info, "Информационное сообщение")
Logger.log(level: .warning, "Предупреждение")
Logger.log(level: .error, "Ошибка: \(error)")
```

## Gotchas

- `UIColor(resource:)` требует, чтобы color set существовал в asset catalog — проверь наличие
- `UIImage(resource:)` требует image set в asset catalog — не путай с `UIImage(systemName:)` (SF Symbols — допустимо)
- `UIImage(systemName:)` — **НЕ нарушение**, это SF Symbols
- `UIColor.black`, `UIColor.white`, `UIColor.clear` — **НЕ нарушение**, это системные цвета
- `UIColor.black.withAlphaComponent()` — **НЕ нарушение** (нет rgb:/hex: в regex)
- Правило `no_navigationcontroller_push` действует только в `Korpu/Modules/`, не в Router или Common
- Папка `Korpu/API` исключена из всех проверок — это автогенерированный код Apollo
