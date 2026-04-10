---
name: x-notification-key
description: Добавь новый AppNotificationKey или используй существующий для межмодульного общения в проекте Korpu. Используй при добавлении нового события/нотификации, подписке на изменения из другого модуля, отправке сигнала между компонентами. Триггер — пользователь просит добавить notification, event, сигнал, подписаться на событие, или нужна коммуникация между модулями без прямой зависимости.
---

# AppNotificationKeys

Добавь или используй типобезопасный notification key для межмодульного общения через async sequence.

## Архитектура

```
AppNotificationKeys (enum)   — все ключи нотификаций приложения
  ├── .name                  — Notification.Name
  ├── .post(payload:)        — отправка
  └── .notifications()       — подписка (AsyncSequence)

Payload (enum)               — типобезопасные данные нотификации
```

**Файл:** `Korpu/Common/Utilities/AppNotificationKeys.swift`

## Подписка на существующий ключ

### Простая подписка (без payload)
```swift
Task { [weak self] in
    for await _ in AppNotificationKeys.reloadFeed.notifications() {
        await self?.reloadData()
    }
}
```

### Подписка с извлечением payload
```swift
Task { [weak self] in
    for await notification in AppNotificationKeys.globalChatMessageReceived.notifications() {
        guard let payload = notification.object as? AppNotificationKeys.Payload,
              case .message(let message) = payload else { continue }
        self?.handleNewMessage(message)
    }
}
```

### Подписка на системные нотификации
```swift
Task { [weak self] in
    for await notification in AppNotificationKeys.sysKeyboardWillChangeFrameNotification.notifications() {
        guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { continue }
        self?.handleKeyboard(endFrame)
    }
}
```

## Отправка нотификации

### Без данных
```swift
AppNotificationKeys.reloadFeed.post(payload: .none)
```

### С payload
```swift
AppNotificationKeys.globalChatMessageReceived.post(payload: .message(messageModel))
AppNotificationKeys.unreadDialogsCountChanged.post(payload: .unreadDialogsCountChanged(count: 5))
AppNotificationKeys.eventsParticipationChanged.post(payload: .eventsParticipationChanged(eventId: 42, isParticipating: true))
```

## Добавление нового ключа

### Шаг 1: Добавь case в AppNotificationKeys

Найди подходящую секцию (по домену) и добавь case:

```swift
enum AppNotificationKeys {
    // ... existing keys grouped by domain

    // MARK: - {Domain}
    case myNewEvent
    case myEventWithData
}
```

### Шаг 2: Добавь payload (если нужны данные)

```swift
enum Payload {
    case none
    // ... existing payloads
    case myEventData(itemId: Int, title: String)
}
```

### Шаг 3: Готово — используй

`.name`, `.post()`, `.notifications()` уже работают через базовую инфраструктуру:

```swift
// Отправка
AppNotificationKeys.myNewEvent.post(payload: .none)
AppNotificationKeys.myEventWithData.post(payload: .myEventData(itemId: 1, title: "Test"))

// Подписка
Task { [weak self] in
    for await notification in AppNotificationKeys.myEventWithData.notifications() {
        guard let payload = notification.object as? AppNotificationKeys.Payload,
              case .myEventData(let itemId, let title) = payload else { continue }
        self?.handle(itemId: itemId, title: title)
    }
}
```

## Паттерны использования

### В Presenter/ViewModel (инициализация)
```swift
final class MyPresenter: BasePresenter<MyViewController> {
    private var observerTasks: [Task<Void, Never>] = []

    func viewDidLoad() {
        setupObservers()
        loadData()
    }

    private func setupObservers() {
        observerTasks = [
            Task { [weak self] in
                for await _ in AppNotificationKeys.reloadFeed.notifications() {
                    await self?.reloadData()
                }
            },
            Task { [weak self] in
                for await _ in AppNotificationKeys.profileNeedsUpdate.notifications() {
                    await self?.refreshProfile()
                }
            }
        ]
    }

    deinit {
        observerTasks.forEach { $0.cancel() }
    }
}
```

### В Singleton/Manager (init)
```swift
final class MyManager {
    init() {
        Task {
            for await _ in AppNotificationKeys.sysDidBecomeActiveNotification.notifications() {
                refreshState()
            }
        }
    }
}
```

### В ViewController (lifecycle tasks)
```swift
final class MyViewController: BaseViewController {
    private var lifecycleTasks: [Task<Void, Never>] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        lifecycleTasks = [
            Task { @MainActor [weak self] in
                for await _ in AppNotificationKeys.sysDidEnterBackgroundNotification.notifications() {
                    self?.pauseVideo()
                }
            },
            Task { @MainActor [weak self] in
                for await _ in AppNotificationKeys.sysDidBecomeActiveNotification.notifications() {
                    self?.resumeVideo()
                }
            }
        ]
    }

    deinit {
        lifecycleTasks.forEach { $0.cancel() }
    }
}
```

## Существующие системные обёртки

| AppNotificationKeys | UIKit Notification |
|--------------------|--------------------|
| `.sysTextDidChangeNotification` | `UITextView.textDidChangeNotification` |
| `.sysKeyboardWillShowNotification` | `UIResponder.keyboardWillShowNotification` |
| `.sysKeyboardWillHideNotification` | `UIResponder.keyboardWillHideNotification` |
| `.sysKeyboardWillChangeFrameNotification` | `UIResponder.keyboardWillChangeFrameNotification` |
| `.sysDidBecomeActiveNotification` | `UIApplication.didBecomeActiveNotification` |
| `.sysDidEnterBackgroundNotification` | `UIApplication.didEnterBackgroundNotification` |
| `.sysDidReceiveMemoryWarningNotification` | `UIApplication.didReceiveMemoryWarningNotification` |
| `.sysCurrentLocaleDidChangeNotification` | `NSLocale.currentLocaleDidChangeNotification` |

## Группировка доменов (существующие)

| Домен | Примеры ключей |
|-------|---------------|
| Auth | `unauthorized`, `authorized` |
| Dialogs | `updateDialog`, `deleteMessage`, `globalChatMessageReceived` |
| Feed | `reloadFeed`, `feedPostDidUpdate`, `newCommentCreated` |
| Events | `updateEvents`, `eventsParticipationChanged` |
| Profile | `profileNeedsUpdate`, `profileDataLoaded` |
| Dating | `hiddenVipButton`, `questionnaireCompleted` |
| Calls | `callMinimized`, `callExpanded`, `callEnded` |
| Health | `healthDataDidUpdate`, `healthAuthStateDidChange` |
| Network | `networkAvailabilityChanged`, `globalNetworkRequestFailed` |
| Media | `mediaTaskStatusChanged`, `mediaPostUploadDidUpdate` |

## Чеклист

- [ ] Case добавлен в `AppNotificationKeys` в правильную секцию (по домену)
- [ ] Если нужны данные — case добавлен в `Payload`
- [ ] Подписка через `Task { for await ... }` с `[weak self]`
- [ ] Task'и сохранены в массив и отменяются в `deinit`
- [ ] Payload извлекается через `guard let ... case` паттерн

## Правила

### DO
- Используй `AppNotificationKeys` для всех межмодульных событий
- Группируй новые ключи по домену с `// MARK: -`
- Всегда `[weak self]` в Task'ах подписки
- Отменяй Task'и в `deinit`
- Используй системные обёртки (`sys*`) вместо прямых `NotificationCenter.default.addObserver`

### DON'T
- **Никогда** `NotificationCenter.default.addObserver` напрямую — используй `AppNotificationKeys.*.notifications()`
- **Никогда** строковые Notification.Name — только через enum
- **Не создавай** отдельные NotificationCenter — используй единый механизм
- **Не забывай** отменять Task'и — иначе утечка памяти

## Gotchas

- `.notifications()` возвращает `NotificationCenter.Notifications` (нативный AsyncSequence iOS 17+)
- `for await` бесконечен — Task будет жить, пока не отменён или объект не деаллоцирован
- `notification.object` содержит `Payload` enum — кастуй через `as? AppNotificationKeys.Payload`
- Системные обёртки (`.sys*`) маппятся на нативные `Notification.Name` в свойстве `.name`
- Кастомные ключи генерируют имя через `String(describing: self)` — коллизий не бывает
- `post(payload:)` передаёт payload через `object:` параметр `NotificationCenter.post`
