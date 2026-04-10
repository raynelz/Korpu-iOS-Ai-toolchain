# Claude Instructions: Архитектура CLAUDE.md + Skills

## Принцип: Стратегия vs Тактика

```
CLAUDE.md        — стратегия: принципы, контекст, ориентация
.claude/skills/  — тактика: конкретные воркфлоу, примеры кода, правила
```

**CLAUDE.md** загружается в контекст **всегда** — при каждом запросе. Поэтому он должен содержать только то, что нужно Claude постоянно держать в голове: архитектурные принципы, ключевые ограничения, указатели на скиллы. Чем длиннее CLAUDE.md, тем больше токенов тратится впустую на каждый запрос.

**Скиллы** загружаются в контекст **по требованию** — только когда Claude распознаёт релевантный запрос. Они могут быть подробными и детальными без штрафа за размер при несвязанных задачах.

---

## Как работают Skills

Основано на [Anthropic Skill Creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).

### Структура скилла

```
.claude/skills/
└── my-skill/
    ├── SKILL.md          ← обязательно
    └── references/       ← опционально: детальная документация
        └── details.md
```

### SKILL.md: обязательные поля

```yaml
---
name: my-skill
description: |
  Описание того, что скилл делает и когда применяется.
  Именно это поле определяет, будет ли скилл вызван.
---
```

### Три уровня прогрессивного раскрытия

| Уровень | Что | Когда в контексте | Объём |
|---------|-----|-------------------|-------|
| 1 | `name` + `description` | Всегда | ~100 слов |
| 2 | Тело `SKILL.md` | При срабатывании скилла | < 500 строк |
| 3 | `references/`, `scripts/`, `assets/` | По запросу из тела | Без ограничений |

### Как скилл срабатывает

Срабатывание управляется **полем `description`**. Claude склонен к undertriggering — к тому, чтобы не применять скилл там, где он был бы полезен. Поэтому описание должно быть «настойчивым»: явно перечислять слова и контексты, при которых скилл нужно применить.

**Слабое описание** (undertrigger):
```
Use when working with fonts.
```

**Сильное описание**:
```
Use this skill whenever working with fonts in the Korpu iOS project. Triggers
when the user wants to set a font, configure a label, style button text, add
a new font weight, update text appearance, or modify Typography.swift. Must be
applied for ALL font-related changes. Also triggers when a user adds a new
label, text field, or text-bearing UI element.
```

---

## Критерии декомпозиции CLAUDE.md → Skills

### Что остаётся в CLAUDE.md

| Критерий | Пример |
|----------|--------|
| Нужно при **каждом** запросе | Структура проекта, минимальная версия iOS |
| Принципы и **почему**, не пошаговые инструкции | «Минимизировать `#if Target` блоки» |
| Стратегические ограничения | «По умолчанию работать с обоими таргетами» |
| Паттерны для распознавания ситуаций | Как понять что перед тобой Korpu-код или Khidi-код |
| Сценарии поведения агента | Как именно отвечать на разные типы запросов |
| Указатели на скиллы | Таблица: когда какой скилл применять |

### Что уходит в Skills

| Критерий | Пример |
|----------|--------|
| Пошаговые воркфлоу | 7 шагов добавления нового компонента в Palette |
| Кодовые примеры | Полные реализации CardView, ProfileViewController |
| DO / DON'T списки с кодом | Антипаттерны с `#if KHIDI`, хардкод шрифтов |
| Полные шаблоны файлов | Весь Typography.swift для Korpu и Khidi |
| Детали иерархий классов | Дерево BaseButton → ... → KONeomorphicButton |
| Специфика конфигурации | Названия провайдеров стилей, свойства кнопок |

### Эвристика: задай себе вопрос

> **«Нужно ли Claude знать это при запросе, не связанном с этой темой?»**
>
> Если нет — это тактика, место в скилле.
> Если да — это стратегия, место в CLAUDE.md.

---

## Скиллы этого проекта

### [`x-palette-manager`](.claude/skills/x-palette-manager/SKILL.md)
**Триггеры:** цвета, изображения, тени, рефакторинг `#if` блоков

Покрывает полный воркфлоу управления Asset Catalog и Palette.swift для обоих таргетов: определение таргета по контексту, структуру xcassets, соглашения по именованию, паттерны (Card, Checkbox, Gradient, ButtonStyling), полный пример с CardView.swift, развёрнутые DO/DON'T с кодом.

### [`x-typography-manager`](.claude/skills/x-typography-manager/SKILL.md)
**Триггеры:** шрифты, лейблы, текстовые элементы, Typography.swift

Полные реализации Typography.swift для Korpu (Manrope + Montserrat) и Khidi (SF Pro + Georgia), примеры использования в ViewController и кастомных вью, таблица размеров по назначению, маппинг весов на `UIFont.Weight`, DO/DON'T с кодом.

### [`x-neomorphic-buttons`](.claude/skills/x-neomorphic-buttons/SKILL.md)
**Триггеры:** кнопки, интерактивные контролы, UIControl

Иерархия классов (BaseButton → KONeomorphicButton), когда использовать KO* vs ConfigurableNeomorphicButton, архитектура ButtonStyleProviding, ButtonVisualStyle, продуктовые провайдеры стилей, press-responders, IconTitleContentView. Запрет NeomorphismButton.

### [`x-neomorphic-views`](.claude/skills/x-neomorphic-views/SKILL.md)
**Триггеры:** карточки, панели, контейнеры, текстовые поля, bottom sheets

Иерархия UIView → KONeomorphicView, NeomorphicViewStyle + StyleProvider, одобренные текстовые поля (KONeomorphicTextField, KOFilledTextField), стандартные bottom sheet компоненты.

---

## Как добавить новый скилл

1. **Определить границу ответственности** — один скилл, одна предметная область
2. **Создать папку** в `.claude/skills/my-skill/`
3. **Написать SKILL.md** с обязательными полями `name` и `description`
4. **Сделать `description` настойчивым** — перечислить конкретные слова и контексты триггера
5. **Убрать дубли из CLAUDE.md** — оставить только принцип, добавить указатель на скилл
6. **Проверить объём** — тело скилла должно быть < 500 строк; если больше — вынести детали в `references/`

### Шаблон SKILL.md

```markdown
---
name: skill-name
description: >
  Use this skill when [конкретные действия]. Triggers when the user [перечисление
  слов и контекстов]. Must be applied for ALL [область]. Also triggers when
  [дополнительные случаи].
---

# Заголовок

Краткое описание назначения.

## Ключевые концепции

[Принципы и архитектурные решения]

## Воркфлоу

[Пошаговые инструкции]

## Примеры

[Кодовые примеры]

## Rules

### DO
[Что делать]

### DON'T
[Чего не делать]
```

---

## Текущий баланс

| Файл | Строк | Роль |
|------|-------|------|
| `CLAUDE.md` | 259 | Стратегия: принципы, сценарии, паттерны |
| `x-palette-manager` | 373 | Тактика: xcassets + Palette.swift |
| `x-typography-manager` | 382 | Тактика: Typography.swift |
| `x-neomorphic-buttons` | 174 | Тактика: иерархия кнопок |
| `x-neomorphic-views` | 99 | Тактика: контейнеры, поля, шторки |
| **Итого** | **1287** | vs 1352 в исходном CLAUDE.md |
