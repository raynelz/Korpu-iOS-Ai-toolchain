---
name: x-ds-audit
description: Проведи аудит модуля на соответствие актуальной дизайн-системе Korpu. Используй когда работаешь с существующим модулем и нужно понять, что ещё не переведено на новую DS. Триггер — пользователь просит проверить модуль, найти устаревшие стили, провести аудит DS, мигрировать на новую дизайн-систему, или просто работает с модулем, в котором встречается deprecated-код. Активируй проактивно, если при работе с модулем замечаешь deprecated-паттерны.
---

# Design System Audit

Проанализируй указанный модуль и выдай отчёт: что использует устаревшие паттерны и на что заменить.

## Scope

Анализируй **только** указанный модуль (папку в `Korpu/Modules/{FeatureName}/`). Не сканируй весь проект.

Если пользователь не указал модуль — спроси, какой модуль проверить.

## Что искать

Проверь каждый `.swift` файл модуля на 7 категорий нарушений ниже. Для каждого найденного — укажи файл, строку, текущий код и готовую замену.

---

### Категория 1: Deprecated цвета (CRITICAL)

**Ищи:**
- `Palette.` (кроме использования внутри самого Palette.swift)
- `PaletteBase.`
- `UIColor(named:`
- `UIColor(rgb:` / `UIColor(hex:` / `#colorLiteral`
- `.init(rgb:` / `.init(hex:`

**Замена:**
```
Palette.*/PaletteBase.*  →  DSBaseVariables.shared.{category}.{name}.uiColor  (UIKit)
                         →  DSBaseVariables.shared.{category}.{name}.color    (SwiftUI)
                         →  Color(uiColor: DSBaseVariables.shared.{category}.{name}.uiColor) (SwiftUI fallback)

UIColor(named: "name")   →  UIColor(resource: .name)  или  DSBaseVariables.shared.*
UIColor(rgb:/hex:)        →  UIColor(resource: .name)  или  DSBaseVariables.shared.*
```

**Маппинг DSBaseVariables категорий:**
| Роль | Токен |
|------|-------|
| Фон основной | `ds.bg.primary` |
| Текст основной | `ds.text.quindenary` |
| Текст вторичный | `ds.text.quattuordenary` |
| Размеры/spacing | `ds.size.val{N}` |

> Если точный маппинг неочевиден — предложи 2-3 варианта и отметь `⚠️ Требует ручного выбора`.

---

### Категория 2: Deprecated типографика (HIGH)

**Ищи:**
- `UIFont(name: "..."` — хардкод имени шрифта
- `UIFont.systemFont(ofSize:` — системный шрифт вместо DS
- `UIFont.boldSystemFont(ofSize:`
- `.font = UIFont(` — любая прямая инициализация UIFont
- Хардкод размеров шрифтов без токенов

**Замена:**
```
UIFont(name: "Manrope-Bold", size: 16)    →  DesignSystemTypography.titleS.font
                                            или Typography.Primary.bold(size: 16)

UIFont.systemFont(ofSize: 14)              →  DesignSystemTypography.textBody1.font
                                            или Typography.Primary.regular(size: 14)

// SwiftUI
Font.system(size: 14)                      →  Font(DesignSystemTypography.textBody1.font)
```

**Доступные стили DesignSystemTypography:**
| Стиль | Типичное использование |
|-------|-----------------------|
| `.buttonL` | Крупные кнопки, заголовки навбара |
| `.titleS` | Подзаголовки, секции |
| `.textBody1` | Основной текст |
| `.textBody2` | Вторичный текст |
| `.caption` | Подписи, метаданные |

> Если точный стиль неочевиден — предложи ближайший по размеру и весу.

---

### Категория 3: Хардкод spacing/padding (MEDIUM)

**Ищи:**
- `.inset(N)` / `.offset(N)` в SnapKit constraints — где N числовой литерал
- `.spacing = N` / `.spacing: N` — в UIStackView
- `.padding(N)` / `.padding(.horizontal, N)` — в SwiftUI
- `CGFloat(N)` для layout-констант
- `private let spacing: CGFloat = N`
- Любые магические числа в layout-коде (8, 12, 16, 20, 24, 32, ...)

**Замена:**
```
.inset(16)                →  .inset(DesignSystemDimens.Base.val16)
.spacing = 8              →  .spacing = DesignSystemDimens.Base.val8
.padding(.horizontal, 16) →  .padding(.horizontal, ds.size.val16)
```

**Доступные токены DesignSystemDimens.Base:**
`val4`, `val6`, `val8`, `val10`, `val12`, `val14`, `val16`, `val20`, `val24`, `val28`, `val32`, `val36`, `val40`, `val44`, `val48`, `val56`, `val64`

> Не помечай как нарушение: `.zero`, `0`, `1` (border), `.greatestFiniteMagnitude`.
> Также допустимы вычисляемые значения на основе токенов.

---

### Категория 4: Хардкод corner radius (MEDIUM)

**Ищи:**
- `.cornerRadius = N` — числовой литерал
- `RoundedRectangle(cornerRadius: N` — SwiftUI
- `.clipShape(RoundedRectangle(cornerRadius: N`
- `layer.cornerRadius = N`

**Замена:**
```
layer.cornerRadius = 12            →  layer.cornerRadius = DesignSystemRadius.val12
RoundedRectangle(cornerRadius: 24) →  RoundedRectangle(cornerRadius: DesignSystemRadius.val24)
```

**Доступные токены:** `DesignSystemRadius.val4`, `val8`, `val12`, `val16`, `val20`, `val24`, `val32`

> Пропускай `.cornerRadius = bounds.height / 2` (круглая форма — не хардкод).

---

### Категория 5: Deprecated компоненты (HIGH)

**Ищи:**
- `NeomorphismButton` — deprecated кнопка
- `NeomorphismView` — deprecated view
- `NeomorphicView` (без "ism") — тоже deprecated

**Замена:**
```
NeomorphismButton  →  ConfigurableNeomorphicButton / KONeomorphicButton + ButtonStyleProvider
NeomorphismView    →  KONeomorphicView + NeomorphicViewStyle
NeomorphicView     →  KONeomorphicView + NeomorphicViewStyle
```

---

### Категория 6: Conditional compilation для стилизации (CRITICAL)

**Ищи:**
- `#if KHIDI` / `#if KORPU` / `#if AURA` / `#if KAMURJ` — в контексте цветов, шрифтов, spacing, радиусов, иконок, теней, градиентов

**Замена:**
```
#if KHIDI
    label.textColor = UIColor(resource: .khidiPrimary)
#else
    label.textColor = UIColor(resource: .primary)
#endif

→  label.textColor = DSBaseVariables.shared.text.primary.uiColor
   // или через Palette, если нет подходящего DS-токена
```

> `#if` допустим для бизнес-логики (feature flags), но НЕ для стилизации.

---

### Категория 7: Устаревшие ObservableObject паттерны (LOW — только SwiftUI)

**Ищи:**
- `@Published var` — в ViewModel
- `@StateObject var` — во View
- `@ObservedObject var` — во View
- `ObservableObject` — конформанс в ViewModel (кроме BaseVM)

**Замена:**
```
@Published var items = []         →  private(set) var items: [Item] = []  (в @Observable классе)
@StateObject var vm               →  @State var vm
@ObservedObject var vm             →  var vm (если передаётся как зависимость)
class VM: ObservableObject         →  @MainActor @Observable final class VM: BaseVM
```

---

## Формат отчёта

Выдай отчёт в таблице, сгруппированный по категориям:

```markdown
## DS Audit: {ModuleName}

### Summary
| Категория | Найдено | Приоритет |
|-----------|---------|-----------|
| Deprecated цвета | N | 🔴 CRITICAL |
| Deprecated типографика | N | 🟠 HIGH |
| Хардкод spacing | N | 🟡 MEDIUM |
| Хардкод radius | N | 🟡 MEDIUM |
| Deprecated компоненты | N | 🟠 HIGH |
| #if для стилизации | N | 🔴 CRITICAL |
| ObservableObject | N | 🔵 LOW |

### Детали

#### 🔴 Deprecated цвета (N найдено)

| Файл:строка | Текущий код | Замена |
|-------------|-------------|--------|
| View.swift:42 | `Palette.Card.bg` | `DSBaseVariables.shared.bg.primary.uiColor` |
| View.swift:58 | `UIColor(named: "red")` | `UIColor(resource: .red)` |

#### 🟠 Deprecated типографика (N найдено)
...
```

## Процедура анализа

1. Определи scope модуля (папку)
2. Прочитай **все** .swift файлы модуля
3. Для каждого файла проверь 7 категорий
4. Для каждого нарушения предложи конкретную замену
5. Если замена неоднозначна — отметь `⚠️ Требует ручного выбора` и предложи варианты
6. Сформируй отчёт

## Gotchas

- `Palette.*` в `Palette.swift` самом — **не нарушение** (это определение)
- `PaletteBase.Primitives.Base.v100` / `v150` пока используется даже в новом коде (для фонов карточек) — помечай как LOW, не CRITICAL
- `UIColor.black`, `.white`, `.clear` — **не нарушение** (системные цвета)
- `UIColor.black.withAlphaComponent()` — **не нарушение**
- `.cornerRadius = bounds.height / 2` — **не нарушение** (вычисляемый)
- `.spacing = .zero` / `spacing: 0` — **не нарушение**
- `#if DEBUG` / `#if targetEnvironment(simulator)` — **не нарушение** (не стилизация)
- Код в `Korpu/API/` исключён из проверки (автогенерированный)
- `ObservableObject` в `BaseVM` — **не нарушение** (базовый класс проекта)
