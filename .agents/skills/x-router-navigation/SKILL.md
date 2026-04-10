---
name: x-router-navigation
description: Добавь новый route и настрой навигацию в проекте Korpu. Используй при добавлении нового экрана в навигацию, создании route с payload, настройке push/present/modal переходов. Триггер — пользователь просит добавить навигацию к новому экрану, создать переход между экранами, добавить route, или настроить deep link.
---

# Router & Navigation Manager

Добавь новый route и настрой навигацию в проекте Korpu. Навигация централизована через Router — все переходы идут через presenter → `module?.router`.

## Архитектура навигации

```
Route.swift          — enum всех маршрутов (source of truth)
RouteRegistry.swift  — маппинг route → создание модуля + DI из AppAssembly
Router.swift         — push/present/pop/setRoot логика
```

**Файлы:**
- `Korpu/Router/Route.swift`
- `Korpu/Router/RouteRegistry.swift`
- `Korpu/Router/Router.swift`

## Шаг 1: Добавь route в Route.swift

### Без payload
```swift
case featureName
```

### С простым payload
```swift
case featureName(userId: Int)
```

### Со сложным payload (struct)
```swift
case featureName(FeatureNamePayload)
```

Payload struct определяй **в начале Route.swift** рядом с другими context-структурами:

```swift
struct FeatureNamePayload {
    let itemId: Int
    let title: String
    let onComplete: ((Bool) -> Void)?

    init(itemId: Int, title: String, onComplete: ((Bool) -> Void)? = nil) {
        self.itemId = itemId
        self.title = title
        self.onComplete = onComplete
    }
}
```

## Шаг 2: Добавь маппинг в RouteRegistry.swift

```swift
case .featureName:
    let module = FeatureNameModule(
        route: route,
        router: router,
        mainNavController: navController
    )
    return module.build(
        someService: appAssembly.someService,
        sessionManager: appAssembly.sessionManager
    )

// С payload
case .featureName(let payload):
    let module = FeatureNameModule(
        route: route,
        router: router,
        mainNavController: navController
    )
    return module.build(
        itemId: payload.itemId,
        someService: appAssembly.someService
    )
```

## Шаг 3: Навигация из Presenter / ViewModel

### Push (добавить в стек)
```swift
// В UIKit Presenter
module?.router.push(route: .featureName)
module?.router.push(route: .featureName(userId: 42))

// В SwiftUI ViewModel
router.push(route: .featureName)
```

### Pop (назад)
```swift
// В UIKit Presenter
module?.router.pop()

// В SwiftUI ViewModel
router.pop()
```

### Pop to root
```swift
module?.router.popToRoot()
```

### Pop to root и сразу push
```swift
module?.router.popToRootAndPush(route: .featureName)
```

### Present (модальное окно)
```swift
module?.router.present(
    route: .featureName,
    mode: .automatic
)
```

### Present bottom sheet
```swift
module?.router.present(
    route: .featureNameSheet,
    with: NavigationContext(isAnimated: false),
    mode: .overFullScreen
)
```

### Present на конкретном ViewController
```swift
module?.router.presentOnHost(
    route: .featureName,
    host: someViewController,
    mode: .overFullScreen
)
```

### Set root (заменить весь стек)
```swift
module?.router.setRoot(
    route: .authorizedZone(isActiveUser: true),
    with: NavigationContext(isAnimated: false)
)
```

## NavigationContext

```swift
NavigationContext(
    isAnimated: true,           // анимация перехода
    interactive: interactiveCtx // интерактивный переход (опционально)
)
```

## Правила навигации

### DO

- Навигация **только** из Presenter/ViewModel → `module?.router` / `router`
- Payload structs рядом с Route.swift (context-структуры) или в папке модуля
- Зависимости (сервисы) передавай через `RouteRegistry` из `appAssembly` — НЕ через payload
- Callback-замыкания в payload — для возврата данных вызывающему модулю
- Bottom sheet route: `mode: .overFullScreen` и `NavigationContext(isAnimated: false)`

### DON'T

- **Никогда** `navigationController?.pushViewController()` из ViewController
- **Никогда** `self.present()` из ViewController для навигации к модулям (допустимо для UIKit alert/sheet)
- **Никогда** передавай сервисы через payload — только данные и callback'и
- **Никогда** навигируй из View напрямую — делегируй в Presenter/ViewModel

## Bottom Sheet через SwiftUI

Когда нужно показать bottom sheet из SwiftUI экрана:

```swift
// В ViewModel
func showSheet() {
    guard let topVC = module?.mainNavController.topViewController else { return }
    let sheet = SomeBottomSheetViewController(...)
    topVC.present(sheet, animated: false)
}
```

## Gotchas

- `Router` использует `RouterActionDebouncer` — быстрые повторные вызовы навигации игнорируются
- `module?.router` в Presenter — optional chain: если module nil, навигация молча не выполнится
- В SwiftUI ViewModel router хранится как обычное свойство (не weak), т.к. ViewModel не владеет router
- Route аналитика: каждый route имеет `analyticsScreenName` — добавь его для нового route
- Screen protection: некоторые route включают защиту от скриншотов через `isScreenProtectionEnabled`
