---
name: x-definition-of-done
description: Проверь готовность задачи перед коммитом. Используй ОБЯЗАТЕЛЬНО после завершения реализации и ПЕРЕД коммитом. Триггер — пользователь говорит «готово», «закончил», «можно коммитить», «проверь», или ты сам считаешь что задача завершена. Никогда не коммить без прохождения этого чеклиста.
---

# Definition of Done

Проверь готовность задачи перед коммитом. Пройди все секции по порядку. Задача считается готовой ТОЛЬКО когда все обязательные пункты выполнены.

## Процедура

Для каждой секции: проверь → отметь результат → если fail, исправь → перепроверь.

---

## 1. Сборка (БЛОКЕР)

```bash
xcodebuild -project Korpu.xcodeproj -scheme Korpu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

- [ ] **Проект компилируется без ошибок**

> Если не компилируется — исправь. Дальше не двигайся.

---

## 2. SwiftLint (БЛОКЕР)

```bash
swiftlint lint --config .swiftlint.yml --path Korpu/Modules/{FeatureName}/
```

- [ ] **0 ошибок SwiftLint** в изменённых файлах

Быстрая проверка изменённых файлов вручную:
- [ ] Нет `print(` → используй `Logger.log()`
- [ ] Нет `UIImage(named:` → используй `UIImage(resource:)`
- [ ] Нет `navigationController?.push` в Modules/ → используй `module?.router`
- [ ] Нет `UIColor(rgb:` / `UIColor(hex:` / `#colorLiteral` → используй DS/Palette/resource

---

## 3. Design System (ОБЯЗАТЕЛЬНО)

- [ ] Цвета через `DSBaseVariables.shared.*` или `UIColor(resource:)` — нет хардкода
- [ ] Шрифты через `DesignSystemTypography.*` или `Typography.*` — нет `UIFont(name:)`
- [ ] Spacing через `DesignSystemDimens.Base.*` — нет магических чисел в layout
- [ ] Радиусы через `DesignSystemRadius.*` — нет хардкод `.cornerRadius = N`
- [ ] Нет deprecated компонентов (`NeomorphismButton`, `NeomorphismView`, `NeomorphicView`)
- [ ] Нет `#if KHIDI` / `#if KORPU` для стилизации

---

## 4. Архитектура (ОБЯЗАТЕЛЬНО)

### Если создан новый модуль:
- [ ] Структура по KO-шаблону (Module + Presenter + View) или SwiftUI (Module + ViewModel + View)
- [ ] Route добавлен в `Route.swift`
- [ ] Маппинг добавлен в `RouteRegistry.swift` с DI из `appAssembly`

### Если создан новый сервис:
- [ ] Зарегистрирован в `AppAssembly.swift` как `lazy var`
- [ ] Инъекция через `RouteRegistry`, не через payload

### Если используется навигация:
- [ ] Навигация только через `module?.router` / `router` из Presenter/ViewModel
- [ ] View/ViewController НЕ навигирует напрямую

### Если SwiftUI:
- [ ] ViewModel: `@MainActor @Observable final class ... : BaseVM`
- [ ] View: `@State var vm` (не `@StateObject`, не `@ObservedObject`)
- [ ] Нет `@Published` — используй обычные `var` / `private(set) var`
- [ ] Зависимости помечены `@ObservationIgnored`

---

## 5. Multi-Target (ОБЯЗАТЕЛЬНО если затронуты ассеты/стили)

- [ ] Изменения работают для **обоих** таргетов (Korpu + Khidi), если пользователь не ограничил scope
- [ ] Новые цвета/изображения добавлены в оба asset catalog (KorpuAssets + KhidiAssets)
- [ ] Оба `Palette.swift` обновлены с идентичными enum/property именами

---

## 6. Качество кода (ОБЯЗАТЕЛЬНО)

- [ ] Нет TODO/FIXME оставленных без объяснения
- [ ] Нет закомментированного кода
- [ ] Нет неиспользуемых import'ов
- [ ] `[weak self]` в Task'ах и замыканиях где нужно
- [ ] Ошибки обрабатываются (не проглатываются молча)
- [ ] Нет force unwrap (`!`) без обоснования

---

## 7. Безопасность (ОБЯЗАТЕЛЬНО)

- [ ] Нет хардкод секретов (API ключи, токены, пароли)
- [ ] Нет `.env`, `.p12`, `.pem`, `.key`, `credentials` в изменённых файлах
- [ ] Чувствительные данные через Keychain / env variables

---

## Формат отчёта

После проверки выдай краткий отчёт:

```
## DoD: {Название задачи}

✅ Сборка — OK
✅ SwiftLint — 0 ошибок
✅ Design System — соответствует
✅ Архитектура — KO-шаблон / SwiftUI module корректен
⬜ Multi-Target — не затронут
✅ Качество кода — OK
✅ Безопасность — OK

Готово к коммиту.
```

Или если есть проблемы:

```
## DoD: {Название задачи}

✅ Сборка — OK
❌ SwiftLint — 2 ошибки
   - MyView.swift:42 — print() → Logger.log()
   - MyView.swift:58 — UIColor(hex:) → DSBaseVariables
⚠️ Design System — 1 замечание
   - MyPresenter.swift:30 — хардкод spacing 16 → DesignSystemDimens.Base.val16

Исправь перед коммитом.
```

---

## Что НЕ входит в DoD

- Тесты (пока отсутствуют в проекте)
- Code review другим человеком (отдельный процесс)
- Push на remote (используй `x-safe-commit` для локального коммита)
- Performance profiling (отдельная задача)
