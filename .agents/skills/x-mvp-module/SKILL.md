---
name: x-mvp-module
description: Создай новый UIKit MVP модуль (KO-шаблон) в проекте Korpu. Используй при создании нового экрана, фичи или модуля на UIKit. Триггер — пользователь просит создать новый экран, модуль, фичу, ViewController. Генерирует Module + Presenter + ViewController с правильной структурой папок, наследованием и DI-связками.
---

# MVP Module Generator (KO-шаблон)

Создай UIKit MVP модуль по KO-шаблону проекта Korpu.

## Иерархия наследования

```
KOModule (protocol)
  └── BaseModule<View: UIViewController & KOViewController, P: KOPresenter>
        └── {Feature}Module: BaseModule<BaseViewController, {Feature}Presenter>

KOPresenter (NSObject)
  └── BasePresenter<ViewControllerType: KOViewController>
        └── {Feature}Presenter: BasePresenter<{Feature}ViewController>

BaseViewController: UIViewController, KOViewController
  └── {Feature}ViewController: BaseViewController
```

## Структура папок

```
Korpu/Modules/{FeatureName}/
├── {FeatureName}Module.swift
├── {FeatureName}Presenter.swift
├── {FeatureName}ViewController.swift
├── Models/              (если нужны модели данных)
└── Subviews/            (если нужны кастомные subview)
```

## Шаг 1: Создай Module

```swift
import UIKit
import SharedAPI

final class {FeatureName}Module: BaseModule<BaseViewController, {FeatureName}Presenter> {
    func build(
        // Перечисли только необходимые сервисы из AppAssembly
        someService: SomeService
    ) -> BaseViewController {
        let view = {FeatureName}ViewController()
        let presenter = {FeatureName}Presenter(
            view: view,
            module: self,
            someService: someService
        )

        view.presenter = presenter
        view.module = self
        self.view = view
        self.presenter = presenter

        return view
    }
}
```

## Шаг 2: Создай Presenter

```swift
import Foundation
import SharedAPI

// Определи протокол ViewInput, если модуль содержит сложную логику обновления UI
protocol {FeatureName}ViewInput: AnyObject {
    func display(items: [SomeModel])
    func setLoading(_ isLoading: Bool)
    func showError(_ message: String)
}

final class {FeatureName}Presenter: BasePresenter<{FeatureName}ViewController> {

    // MARK: - Dependencies

    private let someService: SomeService

    // MARK: - State

    private var items: [SomeModel] = []

    // MARK: - Init

    init(
        view: {FeatureName}ViewController,
        module: (any KOModule)? = nil,
        someService: SomeService
    ) {
        self.someService = someService
        super.init(view: view, module: module)
    }

    // MARK: - Lifecycle

    func viewDidLoad() {
        Task { [weak self] in
            await self?.loadData()
        }
    }

    // MARK: - Actions

    func didTapBack() {
        module?.router.pop()
    }

    // MARK: - Private

    private func loadData() async {
        view?.setLoading(true)
        defer { view?.setLoading(false) }

        do {
            items = try await someService.fetchItems()
            view?.display(items: items)
        } catch {
            view?.showError(error.localizedDescription)
        }
    }
}
```

## Шаг 3: Создай ViewController

```swift
import UIKit
import DSBaseVariables
import SnapKit

@MainActor
final class {FeatureName}ViewController: BaseViewController {

    // MARK: - Typed Presenter

    private var typedPresenter: {FeatureName}Presenter? {
        presenter as? {FeatureName}Presenter
    }

    // MARK: - UI Elements

    // Добавь UI элементы здесь

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        typedPresenter?.viewDidLoad()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DSBaseVariables.shared.bg.primary.uiColor
        // Layout через SnapKit
    }
}

// MARK: - {FeatureName}ViewInput

extension {FeatureName}ViewController: {FeatureName}ViewInput {
    func display(items: [SomeModel]) {
        // Обнови UI
    }

    func setLoading(_ isLoading: Bool) {
        // Покажи/скрой loading
    }

    func showError(_ message: String) {
        // Покажи ошибку
    }
}
```

## Шаг 4: Зарегистрируй в Route и RouteRegistry

1. Добавь case в `Route.swift`:
```swift
case featureName
// или с payload:
case featureName(FeatureNamePayload)
```

2. Добавь маппинг в `RouteRegistry.swift`:
```swift
case .featureName:
    let module = FeatureNameModule(route: route, router: router, mainNavController: navController)
    return module.build(
        someService: appAssembly.someService
    )
```

## Чеклист

- [ ] Module наследует `BaseModule<BaseViewController, {Name}Presenter>`
- [ ] Presenter наследует `BasePresenter<{Name}ViewController>`
- [ ] ViewController наследует `BaseViewController`
- [ ] `build()` содержит полную связку: view ↔ presenter ↔ module
- [ ] Зависимости передаются через параметры `build()`, а не создаются внутри
- [ ] Навигация только через `module?.router` (не `navigationController`)
- [ ] Route добавлен в `Route.swift`
- [ ] Маппинг добавлен в `RouteRegistry.swift` с инъекцией из `appAssembly`
- [ ] Цвета через `DSBaseVariables.shared` или `Palette`, не через raw init
- [ ] `Logger.log()` вместо `print()`
- [ ] `UIImage(resource:)` вместо `UIImage(named:)`

## Gotchas

- `BaseModule` создаётся с `route`, `router`, `mainNavController` — все три обязательны
- `build()` **возвращает** ViewController, а не Module — Router работает с VC
- Presenter хранит `weak var view` (через BasePresenter) — не создавай retain cycle
- Payload struct определяй рядом с Route.swift или в папке модуля, НЕ в ViewController
- Зависимости из `appAssembly` вытаскивай в `RouteRegistry`, НЕ передавай через payload
- Для bottom sheet route используй `mode: .overFullScreen` и `isAnimated: false`
