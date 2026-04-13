---
name: x-figma-token-sync
description: Синхронизирует дизайн-систему проекта с Figma Variables. Сравнивает текущие JSON-токены в DesignSystem/tokens/ с актуальными переменными из Figma DS Base Variables, выдаёт diff (новые/изменённые/удалённые цвета), обновляет JSON и перегенерирует xcassets. Триггер — пользователь просит проверить расхождения с Figma DS, обновить токены, синхронизировать цвета с дизайнерами.
---

# Figma Token Sync

Синхронизирует JSON-токены проекта с Figma Variables.

## Контекст

Проект использует следующий пайплайн:

```
Figma Variables
      ↓  (экспорт в JSON)
DesignSystem/tokens/{category}/Light.tokens.json + Dark.tokens.json
      ↓  python3 DesignSystem/tools/generate_color_assets.py
Korpu/Resources/{Target}/Colors/KOComponentColors.xcassets
      ↓
UIColor(resource: .dsXxx)
      ↓
PaletteBase.* / PaletteGeo.*
```

**Figma файл:** `https://www.figma.com/design/Xw3MAhKCOOUIozqN1YxOBU/DS-Base-Variables`
**File key:** `Xw3MAhKCOOUIozqN1YxOBU`

---

## Структура токенов

```
DesignSystem/tokens/
├── targets.json                        # Таргеты: brand, geo_family, asset_root
├── colors/
│   ├── Light.tokens.json               # Base (50–1000), Elements (e1–e16), Colors (Green/Red/Orange/Yellow), GeoBase (Crimson Red, Cornflower Blue, Turquoise Blue, Tan, ...)
│   └── Dark.tokens.json
├── bg/
│   └── Value.tokens.json               # BG.Full .. BG.Denary (ссылается на Base)
├── bg_geo/
│   ├── AZ.tokens.json                  # BG.Primary/Secondary/Tertiary для таргета
│   ├── GEO.tokens.json
│   └── ... (по brand-коду из targets.json)
├── text/
│   ├── Light.tokens.json               # Text.Base.Primary…Sedenary + Error/Success/Warning
│   └── Dark.tokens.json
├── stroke/
│   ├── Light.tokens.json               # Stroke.Base.*  Stroke.Accent.*
│   └── Dark.tokens.json
├── inputs/
│   ├── Light.tokens.json               # Input.Default.*
│   └── Dark.tokens.json
├── button_primary/
│   └── {brand}.tokens.json             # ButtonPrimary.default/disabled
├── button_disabled/
│   └── Value.tokens.json
├── tab_bar/
│   └── Light.tokens.json
└── values/
    └── (spacing/radius JSON если есть)
```

---

## Шаг 1: Получи переменные из Figma

Используй REST API Figma (требует `FIGMA_API_KEY` в env):

```
GET https://api.figma.com/v1/files/Xw3MAhKCOOUIozqN1YxOBU/variables/local
Header: X-Figma-Token: {FIGMA_API_KEY}
```

Альтернатива — через Figma MCP если доступен (проверь наличие инструмента для variables).

> Если `FIGMA_API_KEY` не задан — предупреди пользователя: `export FIGMA_API_KEY=...` или добавить в `.mcp.json`.

**Из ответа извлеки:**
- `variables` — словарь `{variableId: {name, resolvedType, valuesByMode, variableCollectionId}}`
- `variableCollections` — словарь `{collectionId: {name, modes: [{modeId, name}]}}`

Тебе нужны только переменные с `resolvedType = "COLOR"`.

**Преобразование цвета** из Figma API (r/g/b/a в диапазоне 0–1) в hex:
```python
r, g, b = int(r*255), int(g*255), int(b*255)
hex = f"#{r:02X}{g:02X}{b:02X}"
```

**Построй плоский словарь:**
```
{
  "variableId": {
    "name": "Base/100",        # path из Figma
    "collection": "Colors base",
    "modes": {
      "Light": {"r": 0.97, "g": 0.97, "b": 0.97, "a": 1, "hex": "#F8F8F8"},
      "Dark":  {"r": 0.05, "g": 0.05, "b": 0.05, "a": 1, "hex": "#0D0D0D"}
    }
  }
}
```

---

## Шаг 2: Загрузи текущие токены

Прочитай все `DesignSystem/tokens/**/*.tokens.json` файлы.

Из каждого файла собери плоский словарь, сопоставляя `com.figma.variableId` → текущий hex:
```
{
  "VariableID:1816:429": {
    "file": "DesignSystem/tokens/bg/Value.tokens.json",
    "path": ["Full"],
    "mode": "Light",
    "hex": "#FFFFFF",
    "dark_hex": "#191919"  (если есть тёмный вариант в Dark.tokens.json)
  }
}
```

> Если у токена нет `com.figma.variableId` — он локальный, не трогай его.

---

## Шаг 3: Diff

Сравни Figma-словарь с нашим словарём по `variableId`.

**Три категории изменений:**

### 🟡 Изменённые (variableId совпадает, hex отличается)
```
VariableID:xxx | Base/100 | было #F8F8F8 → стало #F5F5F5 (Light)
VariableID:yyy | Text/Base/Primary | было #000000 → стало #0A0A0A (Dark)
```

### 🟢 Новые (variableId есть в Figma, нет в проекте)
```
VariableID:zzz | Base/1050 (NEW) | Light: #F0F0F0 | Dark: #0F0F0F
VariableID:www | Stroke/Base/undenary (NEW) | ...
```

Для новых — **определи целевой файл** по группе Figma (см. маппинг ниже).

### 🔴 Удалённые (variableId есть в проекте, нет в Figma)
```
VariableID:old | dsCustomColor — есть в коде, удалён из Figma
```

> Удалённые только помечай, **не удаляй автоматически** — нужно ручное подтверждение, потому что токен может использоваться в PaletteBase.

---

## Маппинг: Figma variable name → файл токенов

| Figma group prefix | Файл токенов | Ключ в JSON |
|--------------------|-------------|-------------|
| `Base/` | `colors/Light.tokens.json` + `colors/Dark.tokens.json` | `Base` |
| `Other/Elements/` | `colors/Light.tokens.json` + `colors/Dark.tokens.json` | `Elements` |
| `Other/Colors/Green/` | `colors/Light.tokens.json` | `Colors.Green` |
| `Other/Colors/Red/` | `colors/Light.tokens.json` | `Colors.Red` |
| `Other/Colors/Orange/` | `colors/Light.tokens.json` | `Colors.Orange` |
| `Other/Colors/Yellow/` | `colors/Light.tokens.json` | `Colors.Yellow` |
| `Geo base/` | `colors/Light.tokens.json` → `GeoBase` section | По family name |
| `BG/` | `bg/Value.tokens.json` | корень |
| `BG Geo/` | `bg_geo/{brand}.tokens.json` | корень |
| `Text/Base/` | `text/Light.tokens.json` + `text/Dark.tokens.json` | `Text.Base` |
| `Text/Error/` | `text/Light.tokens.json` + `text/Dark.tokens.json` | `Text.Error` |
| `Text/Success/` | `text/Light.tokens.json` | `Text.Success` |
| `Text/Warning/` | `text/Light.tokens.json` | `Text.Warning` |
| `Stroke/Base/` | `stroke/Light.tokens.json` + `stroke/Dark.tokens.json` | `Stroke.Base` |
| `Stroke/Accent/` | `stroke/Light.tokens.json` | `Stroke.Accent` |
| `Inputs/` | `inputs/Light.tokens.json` | `Input.Default` |
| `Button Primary/` | `button_primary/{brand}.tokens.json` | по brand |
| `Tab Bar/` | `tab_bar/Light.tokens.json` | корень |

> Если маппинг неоднозначен или group не найден в таблице — помечай `⚠️ Требует ручного выбора` и не добавляй автоматически.

---

## Шаг 4: Покажи diff-отчёт

```markdown
## Figma Token Sync — Diff Report

### 🟡 Изменённые цвета (N)
| Figma path | Файл | Режим | Было | Стало |
|-----------|------|-------|------|-------|
| Base/100 | colors/Light.tokens.json | Light | #F8F8F8 | #F5F5F5 |

### 🟢 Новые цвета (N)
| Figma path | Целевой файл | Light | Dark |
|-----------|-------------|-------|------|
| Base/1050 | colors/Light.tokens.json | #F0F0F0 | #0F0F0F |
| Stroke/Base/sedenary+ | ⚠️ Требует ручного выбора | ... | ... |

### 🔴 Удалённые из Figma (N) — только для информации
| variableId | Файл | path |
|-----------|------|------|
| VariableID:old | colors/Light.tokens.json | Base/customX |

### Нет изменений: {список без изменений}
```

**Спроси подтверждение** перед применением:
> Применить изменённые и новые? (удалённые не трогаю) [y/N]

---

## Шаг 5: Обнови JSON-токены

Для каждого **изменённого** — замени `hex` и `components` в соответствующем файле.

Для каждого **нового** — добавь запись в правильный файл. Формат записи:

```json
"{Name}": {
  "$type": "color",
  "$value": {
    "colorSpace": "srgb",
    "components": [R_float, G_float, B_float],
    "alpha": 1,
    "hex": "#RRGGBB"
  },
  "$extensions": {
    "com.figma.variableId": "VariableID:xxx",
    "com.figma.scopes": ["ALL_SCOPES"],
    "com.figma.aliasData": {
      "targetVariableName": "Figma/Path/Here"
    }
  }
}
```

> `components` = `[r/255, g/255, b/255]` как float (не целые)

---

## Шаг 6: Перегенерируй xcassets

```bash
cd /path/to/multiapp
python3 DesignSystem/tools/generate_color_assets.py
```

Если скрипт выдал ошибки — покажи их пользователю и остановись.

---

## Шаг 7: Обнови PaletteBase / PaletteGeo (если нужно)

**Нужно обновлять**, если появились новые токены в PaletteBase/PaletteGeo:
- Новый `Base/N` → добавь `public static let vN = UIColor(resource: .dsBaseN)` в `PaletteBase.Primitives.Base`
- Новый `Text/Base/...` → добавь в `PaletteBase.Text.Base`
- Новый `Stroke/Base/...` → добавь в `PaletteBase.Stroke.Base`
- Новый `Geo base/*/N` → добавь в `PaletteGeo.GeoBase.{FamilyName}`

**Не нужно**, если изменились только значения существующих токенов (xcassets обновит цвет автоматически).

Расположение Palette файлов:
- `Korpu/Resources/PaletteBase.swift` — базовые семантические токены
- `Korpu/Resources/Khidi/Colors/PaletteKhidi.swift` — `PaletteGeo` для GEO/Khidi-таргета
- (аналогично для других таргетов)

---

## Шаг 8: Итог

```markdown
## Sync Complete

✅ Обновлено: N токенов (изменены hex-значения)
✅ Добавлено: N новых токенов в JSON
✅ xcassets перегенерированы
✅ PaletteBase обновлён: N новых записей

⚠️ Требуют ручного решения: N токенов (список)
🔴 Удалены из Figma (не тронуты): N токенов (список)
```

Предложи запустить сборку: `xcodebuild -scheme Korpu build` для проверки что ничего не сломалось.

---

## Gotchas

- `FIGMA_API_KEY` должен иметь доступ к файлу `Xw3MAhKCOOUIozqN1YxOBU` — если `403`, ключ не тот
- Figma возвращает цвета в диапазоне `0.0–1.0`, не `0–255` — конвертируй перед записью в JSON
- `bg/Value.tokens.json` использует алиасы (`{Base.100}` формат), не raw hex — не перезаписывай их как raw hex, оставь алиасы
- Hex-сравнение нечувствительно к регистру (`#F8F8F8` == `#f8f8f8`)
- Если у токена два варианта (Light + Dark) — они в разных файлах (`Light.tokens.json` и `Dark.tokens.json`)
- Файлы `bg/Value.tokens.json` и `bg_geo/*.tokens.json` не имеют Light/Dark разделения — один файл на семантику
- `targets.json` определяет, какой `brand` соответствует какому таргету — используй при обновлении `bg_geo/`, `button_primary/`
- Удалённые токены из Figma могут всё ещё быть нужны в коде — **никогда не удаляй автоматически**
