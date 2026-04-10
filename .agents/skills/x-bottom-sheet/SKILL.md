---
name: x-bottom-sheet
description: Создай bottom sheet в проекте Korpu. Используй при создании модального нижнего листа, выбора из списка, подтверждения действия, или любого popup-контента снизу экрана. Триггер — пользователь просит создать bottom sheet, модальное окно снизу, лист выбора, sheet, или показать контент в выезжающей панели.
---

# Bottom Sheet Generator

Создай bottom sheet с использованием `BaseBottomSheetViewController` проекта Korpu.

## Архитектура Bottom Sheet

```
BaseBottomSheetViewController<ContentView: UIView & BottomSheetContent>
├── BottomSheetContentView          — универсальный контент (title + content + actions)
├── BottomSheetListViewController   — список с выбором (single/multiple)
└── Custom ContentView              — кастомный контент
```

## Три варианта

### Вариант A: Простой bottom sheet с контентом

Для кастомного содержимого (форма, информация, подтверждение).

### Вариант B: Bottom sheet со списком выбора

Для выбора одного или нескольких элементов из списка.

### Вариант C: Полностью кастомный bottom sheet

Для уникального UI (встроенный модуль, сложная композиция).

## Обязательные настройки

Каждый bottom sheet ДОЛЖЕН содержать:

```swift
usesBlurBackground = true   // блюр фона
// mode: .overFullScreen     — устанавливается автоматически в init
```

Grabber: используй системный grabber или отрисовывай вручную внутри ContentView. `grabberAboveOffset` **не использовать** в новом коде.

## Вариант A: Простой Bottom Sheet

### Шаг 1: Создай ContentView

```swift
import UIKit
import SnapKit
import DSBaseVariables

final class {FeatureName}BottomSheetContentView: UIView, BottomSheetContent {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystemTypography.titleS.font
        label.textColor = DSBaseVariables.shared.text.quindenary.uiColor
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystemTypography.textBody1.font
        label.textColor = DSBaseVariables.shared.text.quattuordenary.uiColor
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(title: String, description: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        descriptionLabel.text = description
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - BottomSheetContent

    func preferredHeight() -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: UIScreen.main.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    // MARK: - Setup

    private func setupUI() {
        let stack = UIStackView.vertical(
            spacing: DesignSystemDimens.Base.val8,
            arrangedSubviews: [titleLabel, descriptionLabel]
        )
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(DesignSystemDimens.Base.val16)
        }
    }
}
```

### Шаг 2: Создай ViewController

```swift
import UIKit

final class {FeatureName}BottomSheetViewController:
    BaseBottomSheetViewController<{FeatureName}BottomSheetContentView> {

    private let onConfirm: (() -> Void)?

    init(
        title: String,
        description: String,
        onConfirm: (() -> Void)? = nil
    ) {
        self.onConfirm = onConfirm

        let contentView = {FeatureName}BottomSheetContentView(
            title: title,
            description: description
        )
        super.init(contentView: contentView)

        // Обязательные настройки
        usesBlurBackground = true
        maxHeightRatio = 0.9
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateHeight(animated: false)
    }
}
```

## Вариант B: Bottom Sheet со списком

Используй `BottomSheetListViewController` для выбора из списка:

```swift
// Создание и показ через route
let sheet = BottomSheetListViewController(
    configuration: BottomSheetConfiguration(
        title: "Выберите элемент",
        allowsMultipleSelection: false,
        actions: [],
        cornerRadius: DesignSystemRadius.val24,
        showsGrabber: true,
        backgroundColor: DSBaseVariables.shared.bg.primary.uiColor,
        maxHeightRatio: 0.7
    )
)
sheet.usesBlurBackground = true
```

## Вариант C: Кастомный с встроенным модулем

Для встраивания полноценного модуля (как CommentsBottomSheet):

```swift
final class {FeatureName}BottomSheetViewController:
    BaseBottomSheetViewController<{FeatureName}BottomSheetContentView> {

    private let childViewController: SomeViewController

    init(/* параметры */) {
        // Создай модуль
        let module = SomeModule(
            route: .unknown,
            router: router,
            mainNavController: router.navController
        )
        self.childViewController = module.build(/* сервисы */)

        let contentView = {FeatureName}BottomSheetContentView()
        super.init(contentView: contentView)
        maxHeightRatio = 5.0 / 6.0
        usesBlurBackground = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedChild()
        updateHeight(animated: false)
    }

    private func embedChild() {
        addChild(childViewController)
        contentView.containerView.addSubview(childViewController.view)
        childViewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        childViewController.didMove(toParent: self)
    }
}
```

## Интеграция с Route/Router

### Через Route
```swift
// Route.swift
case featureNameSheet(FeatureNameSheetPayload)

// RouteRegistry.swift
case .featureNameSheet(let payload):
    let vc = FeatureNameBottomSheetViewController(
        title: payload.title,
        onConfirm: payload.onConfirm
    )
    return vc
```

### Показ
```swift
// Из Presenter (UIKit)
module?.router.present(
    route: .featureNameSheet(payload),
    with: NavigationContext(isAnimated: false),
    mode: .overFullScreen
)

// Из ViewModel (SwiftUI)
guard let topVC = module?.mainNavController.topViewController else { return }
let sheet = FeatureNameBottomSheetViewController(title: "Title") {
    // on confirm
}
topVC.present(sheet, animated: false)

// Прямое создание из Presenter без route
let sheet = FeatureNameBottomSheetViewController(...)
view?.present(sheet, animated: true)
```

## Ключевые свойства BaseBottomSheetViewController

| Свойство | Тип | По умолчанию | Описание |
|----------|-----|-------------|----------|
| `usesBlurBackground` | Bool | false | Блюр-фон под sheet |
| `maxHeightRatio` | CGFloat | 0.9 | Макс. высота (доля экрана) |
| `allowsBackgroundTapDismiss` | Bool | true | Закрытие по тапу на фон |
| `allowsPanDismiss` | Bool | true | Закрытие свайпом вниз |
| `followsKeyboard` | Bool | true | Подъём при появлении клавиатуры |

## Чеклист

- [ ] Наследует `BaseBottomSheetViewController<SomeContentView>`
- [ ] ContentView реализует `BottomSheetContent` с `preferredHeight()`
- [ ] `usesBlurBackground = true`
- [ ] Grabber: системный или кастомный внутри ContentView (не `grabberAboveOffset`)
- [ ] Показ: `mode: .overFullScreen` и `isAnimated: false` для route
- [ ] `updateHeight(animated: false)` в `viewDidLoad()` если контент динамический
- [ ] Callback'и для возврата данных (onConfirm, onSelect)
- [ ] Цвета через Design System

## Gotchas

- `mode: .overFullScreen` устанавливается автоматически в `BaseBottomSheetViewController.init` — не нужно задавать вручную
- Для route-based presentation: используй `NavigationContext(isAnimated: false)` — анимацию делает сам sheet
- `preferredHeight()` вызывается для расчёта высоты — если содержимое TableView/CollectionView, `BottomSheetContentView` сам определит высоту
- Dismiss: `softDismiss(completion:)` — с анимацией; или обычный `dismiss(animated:)`
- Для встраивания child VC — используй `addChild` / `didMove(toParent:)` стандартный UIKit паттерн
- `.overFullScreen` **не** вызывает `viewWillDisappear` у presenting VC — учитывай при логике
