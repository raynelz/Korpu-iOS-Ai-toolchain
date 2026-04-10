---
name: x-swiftui-module
description: Создай новый SwiftUI модуль (MVVM внутри MVP-обёртки) в проекте Korpu. Используй при создании нового SwiftUI экрана, фичи на SwiftUI, или когда пользователь просит создать View с ViewModel. Генерирует BaseSUIModule + @Observable ViewModel + SwiftUI View с правильной интеграцией в MVP-инфраструктуру проекта.
---

# SwiftUI Module Generator (MVVM inside MVP)

Создай SwiftUI модуль с MVVM-паттерном внутри MVP-обёртки проекта Korpu.

## Иерархия наследования

```
BaseSUIModule: BaseModule<BaseHostingController, BaseVM>
  └── {Feature}Module: BaseSUIModule

BaseVM: KOPresenter, ObservableObject
  └── @MainActor @Observable {Feature}ViewModel: BaseVM

BaseHostingController: UIHostingController<AnyView>, KOViewController
```

## Два варианта модуля

### Вариант A: Простой модуль (BaseSUIModule + BaseHostingController)

Для большинства экранов. Используй `BaseSUIModule` и `BaseHostingController` напрямую.

### Вариант B: Сложный модуль (Custom BaseModule + Custom HostingController)

Когда нужна клавиатурная обработка, UIKit-мосты, или кастомная логика HostingController.

## Структура папок

### Простой модуль
```
Korpu/Modules/{FeatureName}/
├── {FeatureName}Module.swift      # BaseSUIModule
├── {FeatureName}ViewModel.swift   # @Observable @MainActor ViewModel
└── {FeatureName}View.swift        # SwiftUI View
```

### Сложный модуль
```
Korpu/Modules/{FeatureName}/
├── Assembly/
│   ├── {FeatureName}Module.swift
│   ├── {FeatureName}HostingController.swift
│   └── {FeatureName}HostingState.swift
├── ViewModels/
│   └── {FeatureName}ViewModel.swift
├── Views/
│   └── {FeatureName}View.swift
└── Components/
    └── (вспомогательные SwiftUI View)
```

## Шаг 1: Создай Module (простой вариант)

```swift
import SwiftUI
import UIKit
import SharedAPI

final class {FeatureName}Module: BaseSUIModule {
    func build(
        // Перечисли необходимые сервисы
        someService: SomeService
    ) -> BaseHostingController {
        let presenter = {FeatureName}ViewModel(
            router: router,
            someService: someService
        )

        let view = BaseHostingController(
            rootView: AnyView({FeatureName}View(vm: presenter))
        )

        self.presenter = presenter
        self.view = view
        view.presenter = presenter
        view.module = self

        return view
    }
}
```

## Шаг 2: Создай ViewModel

```swift
import Foundation
import Observation
import SharedAPI

@MainActor
@Observable
final class {FeatureName}ViewModel: BaseVM {

    // MARK: - Observable State

    private(set) var items: [SomeModel] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies (не триггерят SwiftUI обновления)

    @ObservationIgnored
    private let router: Router

    @ObservationIgnored
    private let someService: SomeService

    // MARK: - Init

    init(
        router: Router,
        someService: SomeService
    ) {
        self.router = router
        self.someService = someService
        super.init()
    }

    // MARK: - Actions

    func didTapBack() {
        router.pop()
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await someService.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func didSelectItem(_ item: SomeModel) {
        router.push(route: .itemDetail(item.id))
    }
}
```

## Шаг 3: Создай SwiftUI View

```swift
import DSBaseVariables
import SwiftUI

private let ds = DSBaseVariables.shared

struct {FeatureName}View: View {

    @State var vm: {FeatureName}ViewModel

    var body: some View {
        ZStack(alignment: .top) {
            ds.bg.primary.color
                .ignoresSafeArea()

            VStack(spacing: .zero) {
                DSNavigationBar(
                    style: .adaptivePage,
                    contentTopInset: 0,
                    contentHeight: DesignSystemDimens.Base.val44,
                    backButtonFrameSize: DesignSystemDimens.Base.val44,
                    onBack: { vm.didTapBack() }
                ) {
                    Text("Заголовок")
                        .font(Font(DesignSystemTypography.buttonL.font))
                        .foregroundStyle(ds.text.quindenary.color)
                }

                contentView
            }
        }
        .task {
            await vm.loadData()
        }
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: ds.size.val16) {
                // Контент
            }
            .padding(.horizontal, ds.size.val16)
            .padding(.top, ds.size.val16)
            .padding(.bottom, ds.size.val24)
        }
        .scrollIndicators(.hidden)
    }
}
```

## Шаг 4: Зарегистрируй в Route и RouteRegistry

1. Добавь case в `Route.swift`:
```swift
case featureName
```

2. Добавь маппинг в `RouteRegistry.swift`:
```swift
case .featureName:
    let module = FeatureNameModule(route: route, router: router, mainNavController: navController)
    return module.build(
        someService: appAssembly.someService
    )
```

## Сложный модуль: Custom HostingController

Когда нужна обработка клавиатуры или UIKit-мосты:

### HostingState
```swift
import Observation
import UIKit

@MainActor
@Observable
final class {FeatureName}HostingState {
    var keyboardBottomInset: CGFloat = 0
    var navigationTopInset: CGFloat = 0
    var bottomSafeAreaInset: CGFloat = 0
}
```

### Custom HostingController
```swift
import SwiftUI
import UIKit
import SharedAPI

final class {FeatureName}HostingController: UIHostingController<{FeatureName}View>, KOViewController {
    var presenter: KOPresenter?
    var module: (any KOModule)?
    var networkReachabilityService: NetworkReachabilityService?
    var notificationManager: NotificationManager?

    private let hostingState: {FeatureName}HostingState
    private var keyboardObservers: [NSObjectProtocol] = []

    init(rootView: {FeatureName}View, hostingState: {FeatureName}HostingState) {
        self.hostingState = hostingState
        super.init(rootView: rootView)
    }

    required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = DSBaseVariables.shared.bg.primary.uiColor
        setupKeyboardObservers()
    }

    deinit {
        keyboardObservers.forEach(NotificationCenter.default.removeObserver)
    }

    private func setupKeyboardObservers() {
        let center = NotificationCenter.default
        keyboardObservers = [
            center.addObserver(
                forName: UIResponder.keyboardWillChangeFrameNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboard(notification)
            },
            center.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboard(notification)
            }
        ]
    }

    private func handleKeyboard(_ notification: Notification) {
        guard isViewLoaded else { return }
        let endFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let converted = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        let inset = max(0, overlap - view.safeAreaInsets.bottom)
        if abs(hostingState.keyboardBottomInset - inset) > 0.5 {
            hostingState.keyboardBottomInset = inset
        }
    }
}
```

### Module для сложного варианта
```swift
final class {FeatureName}Module: BaseModule<{FeatureName}HostingController, {FeatureName}ViewModel> {
    func build(someService: SomeService) -> {FeatureName}HostingController {
        let hostingState = {FeatureName}HostingState()
        let presenter = {FeatureName}ViewModel(
            router: router,
            someService: someService
        )
        let rootView = {FeatureName}View(vm: presenter, hostingState: hostingState)
        let view = {FeatureName}HostingController(rootView: rootView, hostingState: hostingState)

        view.presenter = presenter
        view.module = self
        self.view = view
        self.presenter = presenter

        return view
    }
}
```

## Чеклист

- [ ] ViewModel помечен `@MainActor @Observable` и наследует `BaseVM`
- [ ] Зависимости в ViewModel помечены `@ObservationIgnored`
- [ ] SwiftUI View использует `@State var vm` для владения ViewModel
- [ ] **НЕ используются** `@Published`, `@StateObject`, `@ObservedObject`
- [ ] Module build() связывает: presenter ↔ view ↔ module
- [ ] Навигация через `router.push()` / `router.pop()` из ViewModel
- [ ] Цвета через `DSBaseVariables.shared` — `ds.bg.primary.color`, `ds.text.quindenary.color`
- [ ] Типографика через `Font(DesignSystemTypography.buttonL.font)`
- [ ] Отступы через `DesignSystemDimens` — `ds.size.val16`, `ds.size.val24`
- [ ] Route добавлен в `Route.swift`
- [ ] Маппинг добавлен в `RouteRegistry.swift`
- [ ] Bottom sheet из SwiftUI: `module?.mainNavController.topViewController?.present(sheet, animated: false)`

## Gotchas

- `BaseVM` уже наследует `ObservableObject`, но в проекте используется `@Observable` (Observation framework) — НЕ `@Published`
- `@State var vm` в View — стандарт проекта, НЕ `@ObservedObject` или `@StateObject`
- `@ObservationIgnored` на зависимостях (router, services) — иначе SwiftUI будет лишний раз перерисовывать
- Простой модуль оборачивает View в `AnyView()` для `BaseHostingController`
- Для `DSNavigationBar` используй `style: .adaptivePage` и `backButtonFrameSize: DesignSystemDimens.Base.val44`
- `view.backgroundColor` устанавливай в HostingController/Module, чтобы избежать белой вспышки при переходе
- `super.init()` в ViewModel — обязательно (BaseVM : KOPresenter : NSObject)
