---
name: x-figma-to-code
description: Конвертируй Figma-дизайн в Swift-код проекта Korpu. Используй когда пользователь даёт ссылку на Figma, скриншот дизайна, или просит реализовать экран по макету. Триггер — Figma-ссылка, скриншот UI, просьба сверстать экран, реализовать дизайн, или сделать по макету.
---

# Figma To Code

Конвертируй Figma-дизайн в Swift-код, используя Design System проекта Korpu.

## Процедура

### Шаг 1: Инспекция дизайна

Проинспектируй дизайн через Figma MCP (или скриншот) и извлеки:
- Цвета (фоны, тексты, бордеры, тени)
- Типографику (шрифт, размер, вес, line height)
- Spacing (отступы между элементами, padding внутри)
- Радиусы скруглений
- Структуру компонентов (что вложено во что)

### Шаг 2: Маппинг на Design System

Для каждого извлечённого значения найди соответствие в DS:

| Извлечено из Figma | Ищи в DS |
|---------------------|----------|
| Цвет фона | `DSBaseVariables.shared.bg.*` |
| Цвет текста | `DSBaseVariables.shared.text.*` |
| Шрифт + размер | `DesignSystemTypography.*` или `Typography.Primary/Secondary` |
| Spacing / padding | `DesignSystemDimens.Base.val{N}` |
| Corner radius | `DesignSystemRadius.val{N}` |
| Компонент (кнопка, карточка...) | Существующие DS-компоненты (`DSButton`, `DSNavigationBar`, ...) |

**Правила маппинга:**
- Если значение из Figma **близко** к существующему токену — используй существующий токен
- Не вводи новый токен ради одного экрана
- Новый токен оправдан только если: (1) смысл не покрыт, (2) переиспользуем, (3) принадлежит системе

### Шаг 3: Поиск существующих DS-компонентов

Перед реализацией найди в кодовой базе готовые компоненты:

```
DSButton, DSNavigationBar, DSTextField, DSLabel
BaseBottomSheetViewController, BottomSheetContentView
KONeomorphicButton, KONeomorphicView
IconTitleContentView
```

Для каждого элемента на макете спроси: **есть ли уже готовый DS-компонент?**

Типичные маппинги:
| Элемент Figma | DS-компонент |
|---------------|-------------|
| Кнопка | `DSButton` / `KONeomorphicButton` |
| Навбар с back | `DSNavigationBar(style: .adaptivePage)` |
| Текстовое поле | `DSTextField` / `KOTextField` |
| Bottom sheet | `BaseBottomSheetViewController` |
| Карточка | `KONeomorphicView` |
| Список | `UITableView` / `List` с DS-стилями |

### Шаг 4: Реализация

Собери экран из найденных DS-примитивов:

**SwiftUI (предпочтительно):**
```swift
private let ds = DSBaseVariables.shared

struct FeatureView: View {
    var body: some View {
        ZStack(alignment: .top) {
            ds.bg.primary.color.ignoresSafeArea()
            VStack(spacing: .zero) {
                DSNavigationBar(style: .adaptivePage, ...) { ... }
                ScrollView {
                    VStack(spacing: ds.size.val16) {
                        // Контент из DS-примитивов
                    }
                    .padding(.horizontal, ds.size.val16)
                }
            }
        }
    }
}
```

**UIKit:**
```swift
view.backgroundColor = DSBaseVariables.shared.bg.primary.uiColor
label.font = DesignSystemTypography.titleS.font
label.textColor = DSBaseVariables.shared.text.quindenary.uiColor
stack.spacing = DesignSystemDimens.Base.val8
layer.cornerRadius = DesignSystemRadius.val12
```

### Шаг 5: Валидация

Проверь реализацию:
- [ ] Все цвета через `DSBaseVariables` или `UIColor(resource:)` — нет хардкода
- [ ] Все шрифты через `DesignSystemTypography` или `Typography` — нет `UIFont(name:)`
- [ ] Все отступы через `DesignSystemDimens` — нет магических чисел
- [ ] Все радиусы через `DesignSystemRadius` — нет хардкода
- [ ] Нет `#if KHIDI`/`#if KORPU` для стилизации
- [ ] Использованы DS-компоненты где возможно
- [ ] Новые компоненты созданы только если паттерн реально переиспользуем

## НЕ делай

- Не хардкодь цвета, шрифты, spacing, радиусы в коде фичи
- Не создавай локальные styling-enum внутри экрана
- Не используй `#if` для target-специфичной стилизации
- Не пересоздавай контрол, если DS-аналог уже существует
- Не используй deprecated компоненты (`NeomorphismButton`, `NeomorphismView`, `Palette.*` как primary source)
- Не вводи новый DS-токен если существующий подходит по смыслу

## Gotchas

- `PaletteBase.Primitives.Base.v100` / `v150` пока используются для фонов карточек — это допустимо
- Figma может показывать абсолютные px — конвертируй в pt (1:1 на iOS)
- Figma Auto Layout ≈ `UIStackView` / `VStack`/`HStack` в SwiftUI
- Figma Frame с Fill → `backgroundColor` + `clipShape`/`cornerRadius`
