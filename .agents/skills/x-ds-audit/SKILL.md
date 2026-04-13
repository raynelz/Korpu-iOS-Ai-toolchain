---
name: x-ds-audit
description: Проведи аудит модуля на соответствие актуальной дизайн-системе Korpu. Используй когда работаешь с существующим модулем и нужно понять, что ещё не переведено на новую DS. Триггер — пользователь просит проверить модуль, найти устаревшие стили, провести аудит DS, мигрировать на новую дизайн-систему, или просто работает с модулем, в котором встречается deprecated-код. Активируй проактивно, если при работе с модулем замечаешь deprecated-паттерны.
---

# Design System Audit

Проанализируй указанный модуль и выдай отчёт: что использует устаревшие паттерны и на что заменить.

## Scope

Анализируй **только** указанный модуль (папку в `Korpu/Modules/{FeatureName}/`). Не сканируй весь проект.

Если пользователь не указал модуль — спроси, какой модуль проверить.

---

## Иерархия цветов (обязательно знать перед аудитом)

Новая DS имеет **4 уровня**. Используй в порядке приоритета:

| Уровень | Откуда | Когда использовать |
|---------|--------|--------------------|
| 1. Semantic base | `PaletteBase.*` | Нейтральные семантические: фоны, тексты, иконки, обводки, Primitives, Opacity |
| 2. Semantic geo | `PaletteGeo.*` | Акцент/бренд/гео: кнопки, accent-цвета, гео-специфичные тексты/иконки |
| 3. Component tokens | `PaletteElements.*` | Состояния компонентов: ButtonPrimary, ButtonDisabled, Radio, Input |
| 4. Module-level Config/Style | `{Module}Config` / `{Module}Style` | Специфичные для модуля значения, не покрытые уровнями 1–3 |

**Если цвет не найден ни в PaletteBase, ни в PaletteGeo, ни в PaletteElements — НЕ добавляй его в Palette-уровень.** Вместо этого помести в модульный Config/Style файл (например, `DialogConfig`, `SignInConfig`, `CallsConfig`).

### Доступные токены PaletteBase

```swift
// BG
PaletteBase.BG.full / .primary / .secondary / .tertiary / .quaternary / .quinary
           .senary / .septenary / .octonary / .nonary / .denary

// Text (Base)
PaletteBase.Text.Base.primary … .sedenary  (16 значений)
// Text (Accent)
PaletteBase.Text.Error.default / .pressed / .disabled
PaletteBase.Text.Success.default / .pressed / .disabled
PaletteBase.Text.Warning.default / .pressed / .disabled

// Icon (Base + Accent — аналогично Text)
PaletteBase.Icon.Base.primary … .sedenary
PaletteBase.Icon.Error / .Success / .Warning

// Stroke / Border
PaletteBase.Stroke.Base.primary … .sedenary
PaletteBase.Stroke.Accent.Error / .Success / .Warning
PaletteBase.Border.primary … .quinary
PaletteBase.Border.Accent.success / .warning / .error

// Primitives
PaletteBase.Primitives.Base.v50 … v1000
PaletteBase.Primitives.Elements.e1 … e16
PaletteBase.Primitives.Green / Red / Orange / Yellow / .v100 … v1100

// Opacity
PaletteBase.Opacity.White.v100 … v1000
PaletteBase.Opacity.Black.v100 … v1000

// Button (Gold — только для Gold-кнопок)
PaletteBase.ButtonGradient.Gold.Default.leading / .center / .trailing / .stroke / .text / .icon
PaletteBase.ButtonGradient.Gold.Disabled.*

// Input
PaletteBase.Input.Default.background / .textActive / .textDisabled / .iconActive / .iconDisabled
```

### Доступные токены PaletteGeo

```swift
// GeoBase (гео-специфичный акцентный цвет таргета)
PaletteGeo.GeoBase.BaseBlue.v100 … v1200  // алиас на таргет-цвет
PaletteGeo.GeoBase.CrimsonRed.v100 … v1200
PaletteGeo.GeoBase.CornflowerBlue.v100 … v1200

// Semantic geo
PaletteGeo.BG.primary / .secondary / .tertiary
PaletteGeo.Text.primary / .secondary / .tertiary
PaletteGeo.Icon.primary / .secondary / .tertiary
PaletteGeo.Stroke.primary / .secondary / .tertiary

// Button gradient (основная цветная кнопка таргета)
PaletteGeo.ButtonGradient.Default.leading / .center / .trailing / .stroke / .text / .icon
PaletteGeo.ButtonGradient.Disabled.*
```

### Доступные токены PaletteElements

```swift
PaletteElements.ButtonPrimary.background / .text / .icon
PaletteElements.ButtonDisabled.background / .text / .icon
PaletteElements.Input  // == PaletteBase.Input
// + прочие компонентные состояния (Radio, ...)
```

---

## Что искать

Проверь каждый `.swift` файл модуля на 8 категорий нарушений. Для каждого найденного — укажи файл, строку, текущий код и готовую замену.

---

### Категория 1: Deprecated цвета (CRITICAL)

**Ищи:**
- `DSBaseVariables.` — **deprecated, основной кейс**
- `Palette.` (кроме использования внутри самого Palette.swift)
- `UIColor(named:`
- `UIColor(rgb:` / `UIColor(hex:` / `#colorLiteral`
- `.init(rgb:` / `.init(hex:`

**Замена — определи по смыслу:**

```swift
// DSBaseVariables → PaletteBase / PaletteGeo
DSBaseVariables.shared.bg.primary         →  PaletteBase.BG.primary
DSBaseVariables.shared.text.primary       →  PaletteBase.Text.Base.primary
DSBaseVariables.shared.text.quindenary    →  PaletteBase.Text.Base.quindenary
DSBaseVariables.shared.icon.primary       →  PaletteBase.Icon.Base.primary
DSBaseVariables.shared.stroke.primary     →  PaletteBase.Stroke.Base.primary

// Акцентные / кнопочные → PaletteGeo
// Нейтральные / семантические → PaletteBase

// UIColor(named:) → UIColor(resource: .name)  или  PaletteBase.*
// UIColor(rgb:/hex:) → UIColor(resource: .name)  или  PaletteBase.*
```

> **Если подходящий токен в PaletteBase/PaletteGeo не найден:**
> Не добавляй в Palette. Помести значение в модульный Config/Style файл:
>
> ```swift
> // DialogConfig.swift
> enum DialogConfig {
>     enum Message {
>         static let bubbleBackground = PaletteBase.Primitives.Base.v50  // или raw UIColor(resource:)
>     }
> }
> // Использование:
> view.backgroundColor = DialogConfig.Message.bubbleBackground
> ```

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
```swift
UIFont(name: "Manrope-Bold", size: 16)  →  DesignSystemTypography.titleS.font
                                         или  Typography.Primary.bold(size: 16)

UIFont.systemFont(ofSize: 14)            →  DesignSystemTypography.textBody1.font
                                         или  Typography.Primary.regular(size: 14)

// SwiftUI
Font.system(size: 14)                    →  Font(DesignSystemTypography.textBody1.font)
```

**Доступные стили DesignSystemTypography:**
| Стиль | Типичное использование |
|-------|-----------------------|
| `.heading3` | Заголовки экранов |
| `.heading4` | Подзаголовки, крупные секции |
| `.buttonL` | Крупные кнопки, заголовки навбара |
| `.titleS` | Подзаголовки, секции |
| `.textBody1` … `.textBody5` | Основной и вторичный текст |
| `.label1` … `.label2` | Подписи, метаданные |
| `.caption` | Мелкие подписи |

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
```swift
.inset(16)                →  .inset(DesignSystemDimens.Base.val16)
.spacing = 8              →  .spacing = DesignSystemDimens.Base.val8
.padding(.horizontal, 16) →  .padding(.horizontal, DesignSystemDimens.Base.val16)
```

**Доступные токены DesignSystemDimens.Base:**
`val2`, `val4`, `val6`, `val8`, `val10`, `val12`, `val14`, `val16`, `val20`, `val24`, `val28`, `val32`, `val36`, `val40`, `val44`, `val48`, `val50`, `val56`, `val64`

> Не помечай как нарушение: `.zero`, `0`, `1` (border), `.greatestFiniteMagnitude`.
> Допустимы вычисляемые значения на основе токенов.

---

### Категория 4: Хардкод corner radius (MEDIUM)

**Ищи:**
- `.cornerRadius = N` — числовой литерал
- `RoundedRectangle(cornerRadius: N` — SwiftUI
- `.clipShape(RoundedRectangle(cornerRadius: N`
- `layer.cornerRadius = N`

**Замена:**
```swift
layer.cornerRadius = 12             →  layer.cornerRadius = DesignSystemRadius.val12
RoundedRectangle(cornerRadius: 24)  →  RoundedRectangle(cornerRadius: DesignSystemRadius.val24)
```

**Доступные токены DesignSystemRadius:**
`val4` / `val8` / `val11` / `val12` / `val16` / `val20` / `val24` / `val26` / `val32`
(также алиасы: `space11`, `space16`, `space26`)

> Пропускай `.cornerRadius = bounds.height / 2` (круглая форма — не хардкод).

---

### Категория 5: Deprecated компоненты (HIGH)

**Ищи:**
- `NeomorphismButton` — deprecated кнопка
- `NeomorphismView` — deprecated view (если используется снаружи DialogStyle/Config)
- `NeomorphicView` (без "ism") — тоже deprecated

**Замена:**
```swift
NeomorphismButton  →  ConfigurableNeomorphicButton / KONeomorphicButton + ButtonStyleProvider
NeomorphismView    →  KONeomorphicView + NeomorphicViewStyle
NeomorphicView     →  KONeomorphicView + NeomorphicViewStyle
```

> `NeomorphismView` внутри `DialogStyle.swift` и `DialogConfig.swift` — **не нарушение** (изолировано в Style-файле).

---

### Категория 6: Conditional compilation для стилизации (CRITICAL)

**Ищи:**
- `#if KHIDI` / `#if KORPU` / `#if AURA` / `#if KAMURJ` — в контексте цветов, шрифтов, spacing, радиусов, иконок, теней, градиентов

**Замена:**
```swift
// ❌ Было
#if KHIDI
    label.textColor = UIColor(resource: .khidiPrimary)
#else
    label.textColor = UIColor(resource: .primary)
#endif

// ✅ Стало — через PaletteGeo (таргет-специфичный цвет автоматически)
label.textColor = PaletteGeo.Text.primary

// ✅ Или изолировано в Config/Style файле модуля, где #if оправдан контекстом
```

> `#if` допустим:
> - Для бизнес-логики / feature flags
> - Внутри `{Module}Config` / `{Module}Style` файлов — там это легально и намеренно изолировано
> - `#if DEBUG` / `#if targetEnvironment(simulator)` — не стилизация

---

### Категория 7: Устаревший addTarget вместо addAction (MEDIUM — только UIKit)

**Ищи:**
- `.addTarget(` — любой вызов `UIControl.addTarget(_:action:for:)`

**Замена:**

```swift
// ❌ Старый способ
button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
@objc private func handleTap() { ... }

// ✅ Современный (iOS 14+, минтаргет проекта iOS 18)
button.addAction(UIAction { [weak self] _ in
    self?.handleTap()
}, for: .touchUpInside)
```

> `addTarget` в тестах или системных делегатах (например `UIBarButtonItem`) — не нарушение.

---

### Категория 8: Устаревшие ObservableObject паттерны (LOW — только SwiftUI)

**Ищи:**
- `@Published var` — в ViewModel
- `@StateObject var` — во View
- `@ObservedObject var` — во View
- `ObservableObject` — конформанс в ViewModel (кроме BaseVM)

**Замена:**
```swift
@Published var items = []          →  private(set) var items: [Item] = []  (в @Observable классе)
@StateObject var vm                →  @State var vm
@ObservedObject var vm             →  var vm (если передаётся как зависимость)
class VM: ObservableObject         →  @MainActor @Observable final class VM: BaseVM
```

---

## Паттерн модульного Config/Style файла

Когда цвет/значение не покрыты PaletteBase/PaletteGeo/PaletteElements — создай или дополни Config/Style файл модуля:

```swift
// Korpu/Modules/MyFeature/MyFeatureConfig.swift
import UIKit

enum MyFeatureConfig {
    enum Appearance {
        // Цвет берётся из PaletteBase/PaletteGeo если близкий есть, иначе raw:
        static let specialBackground = UIColor(resource: .myFeatureBg)
        static let accentText = PaletteGeo.Text.primary
        static let cardBorder = PaletteBase.Border.secondary
    }

    enum Layout {
        static let cardCornerRadius: CGFloat = DesignSystemRadius.val16
        static let contentInset: CGFloat = DesignSystemDimens.Base.val16
    }
}
```

**Принципы:**
- Один файл на модуль (не дроби по экранам без нужды)
- Вложенные enum по смысловым зонам (Header, Message, InputBar, ...)
- `#if TARGET` допустим **только** здесь, не в View-коде
- Используй из View так: `view.backgroundColor = MyFeatureConfig.Appearance.specialBackground`

---

## Формат отчёта

```markdown
## DS Audit: {ModuleName}

### Summary
| Категория | Найдено | Приоритет |
|-----------|---------|-----------|
| Deprecated DSBaseVariables / Palette | N | 🔴 CRITICAL |
| Deprecated типографика | N | 🟠 HIGH |
| Хардкод spacing | N | 🟡 MEDIUM |
| Хардкод radius | N | 🟡 MEDIUM |
| Deprecated компоненты | N | 🟠 HIGH |
| #if для стилизации вне Config | N | 🔴 CRITICAL |
| addTarget вместо addAction | N | 🟡 MEDIUM |
| ObservableObject | N | 🔵 LOW |

### Детали

#### 🔴 Deprecated цвета (N найдено)

| Файл:строка | Текущий код | Замена |
|-------------|-------------|--------|
| View.swift:42 | `DSBaseVariables.shared.bg.primary` | `PaletteBase.BG.primary` |
| View.swift:58 | `UIColor(named: "red")` | `UIColor(resource: .red)` |

#### 🟠 Deprecated типографика (N найдено)
...

### Рекомендации по Config/Style файлу
Если нужно добавить значения не из PaletteBase/PaletteGeo — создай/дополни:
`Korpu/Modules/{ModuleName}/{ModuleName}Config.swift`
```

---

## Процедура анализа

1. Определи scope модуля (папку)
2. Прочитай **все** .swift файлы модуля
3. Для каждого файла проверь 8 категорий
4. Для каждого нарушения предложи конкретную замену согласно иерархии цветов
5. Если замена неоднозначна — отметь `⚠️ Требует ручного выбора` и предложи варианты
6. Если цвет не найден ни в PaletteBase, ни в PaletteGeo — укажи куда добавить в Config/Style
7. Сформируй отчёт

---

## Gotchas

- `DSBaseVariables` — **deprecated целиком**, любое использование = нарушение CRITICAL
- `Palette.*` в `PaletteKhidi.swift` / `PaletteKorpu.swift` самом — **не нарушение** (определение)
- `PaletteBase.Primitives.Base.v100` / `v50` в новом коде **допустимо** (это raw-примитив PaletteBase, не deprecated)
- `UIColor.black`, `.white`, `.clear` — **не нарушение** (системные цвета)
- `UIColor.black.withAlphaComponent()` — **не нарушение**
- `.cornerRadius = bounds.height / 2` — **не нарушение** (вычисляемый)
- `.spacing = .zero` / `spacing: 0` — **не нарушение**
- `#if DEBUG` / `#if targetEnvironment(simulator)` — **не нарушение** (не стилизация)
- `#if TARGET` внутри `*Config.swift` / `*Style.swift` — **допустимо** (намеренная изоляция)
- `NeomorphismView` внутри `DialogStyle.swift` — **не нарушение** (изолировано)
- Код в `Korpu/API/` исключён из проверки (автогенерированный)
- `ObservableObject` в `BaseVM` — **не нарушение** (базовый класс)
- `Typography.Primary.regular(N)` / `Typography.Primary.semibold(N)` — допустимо (не deprecated)
