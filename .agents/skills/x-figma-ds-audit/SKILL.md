---
name: x-figma-ds-audit
description: Проверь Figma-дизайн на соответствие Design System и исправь несоответствия в коде. Триггер — пользователь скидывает ссылку на Figma-фрейм/флоу и просит проверить цвета, типографику или привести код в соответствие с макетом. Требует: Figma MCP (Dev Mode), модуль уже существует в коде.
---

# Figma DS Audit

Сравни Figma-дизайн с реализацией и исправь несоответствия через DS-токены.

## Требования

- Figma MCP настроен (`.mcp.json` содержит `figma`, `FIGMA_API_KEY` задан)
- Модуль уже существует в `Korpu/Modules/{Feature}/`
- Ссылка на Figma-фрейм/флоу от пользователя

## Шаг 1: Получи дизайн-контекст из Figma

Вызови `get_design_context` с URL который скинул пользователь.

Из ответа извлеки:
- **Цвета** — все `fill`, `stroke`, `background` значения (`#RRGGBB`, `rgba(...)`)
- **Типографика** — `fontSize`, `fontFamily`, `fontWeight`
- **Отступы** — `padding`, `gap`, `margin` числовые значения
- **Радиусы** — `borderRadius` значения

## Шаг 2: Маппинг Figma → DS-токены

### Цвета

Сравни каждый hex/rgba из Figma с палитрой DSBaseVariables. Маппинг:

| Figma значение | DSBaseVariables токен | UIKit | SwiftUI |
|---------------|----------------------|-------|---------|
| Основной фон | `ds.bg.primary` | `.uiColor` | `.color` |
| Основной текст | `ds.text.quindenary` | `.uiColor` | `.color` |
| Вторичный текст | `ds.text.quattuordenary` | `.uiColor` | `.color` |
| Акцент / кнопки | `ds.bg.accent` (уточни по макету) | `.uiColor` | `.color` |

Если точного совпадения нет — отметь `⚠️ Требует ручного маппинга` и предложи 2-3 ближайших токена.

**Не трогай:** `UIColor.black`, `.white`, `.clear`, системные цвета iOS.

### Типографика

| Figma | DesignSystemTypography |
|-------|----------------------|
| Bold 24+ | `.buttonL` |
| Bold 18-22 | `.titleS` |
| Regular 16 | `.textBody1` |
| Regular 14 | `.textBody2` |
| Regular 12 | `.caption` |

### Spacing

Округли до ближайшего токена `DesignSystemDimens.Base.val{N}`:
`val4, val6, val8, val10, val12, val14, val16, val20, val24, val28, val32, val36, val40, val44, val48, val56, val64`

### Radius

Округли до ближайшего `DesignSystemRadius.val{N}`:
`val4, val8, val12, val16, val20, val24, val32`

## Шаг 3: Найди несоответствия в коде

Используй `mcp__serena__find_symbol` и `mcp__serena__get_symbols_overview` чтобы найти в Swift-файлах модуля хардкод значений из Figma.

Ищи:
- Hex/rgb совпадающие с Figma-цветами
- Числа совпадающие с Figma-отступами/радиусами
- Хардкод шрифтов совпадающий с Figma-типографикой

## Шаг 4: Выведи отчёт

```markdown
## Figma DS Audit: {FrameName} → {ModuleName}

### Цвета (N несоответствий)
| Figma | Текущий код | Замена |
|-------|-------------|--------|
| #1A1A2E (основной фон) | `UIColor(hex: "1A1A2E")` в View.swift:42 | `DSBaseVariables.shared.bg.primary.uiColor` |

### Типографика (N несоответствий)
...

### Spacing / Radius (N несоответствий)
...

### ⚠️ Требует ручного маппинга
- Цвет #FF5733 — нет точного токена. Варианты: ds.bg.accent / ds.text.error / UIColor(resource: .customRed)
```

## Шаг 5: Исправь автоматически

Для каждого несоответствия с однозначным маппингом — исправь через `mcp__serena__replace_symbol_body` или Edit.

Для `⚠️ Требует ручного маппинга` — спроси пользователя перед правкой.

После правок — сообщи итог и предложи запустить скилл `x-swiftlint-check`.

## Gotchas

- Figma MCP работает на уровне файла, не конкретного фрейма — убедись что пользователь открыл нужный фрейм в Figma перед вызовом `get_design_context`
- DS-токены зависят от таргета (Korpu vs Khidi) — уточни у пользователя какой таргет проверяем
- Цвета в Figma могут быть в opacity — `rgba(26, 26, 46, 0.5)` — это не то же что `#1A1A2E`, уточни намерение
