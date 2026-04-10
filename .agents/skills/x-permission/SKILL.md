---
name: x-permission
description: Добавь новый системный permission в проекте Korpu. Используй при добавлении нового типа разрешения (календарь, Bluetooth, трекинг и т.д.) или при работе с существующими permissions (камера, микрофон, галерея, геолокация, контакты, уведомления). Триггер — пользователь просит добавить permission, запросить разрешение, проверить доступ к системной возможности.
---

# Permission Manager

Добавь или используй системное разрешение через `PermissionsManager` проекта Korpu.

## Архитектура

```
PermissionsProviding (protocol)     — @MainActor, async API
  └── PermissionsManager            — @Observable @MainActor, singleton в AppAssembly
PermissionType (enum)               — поддерживаемые разрешения
PermissionStatus (enum)             — notDetermined, authorized, denied, restricted, limited
```

**Файлы:**
```
Korpu/Managers/PermissionsManager/
├── PermissionsProviding.swift     # Протокол
├── PermissionType.swift           # Enum типов
├── PermissionStatus.swift         # Enum статусов
└── PermissionsManager.swift       # Реализация
```

## Существующие permissions

| PermissionType | Framework | Plist Key |
|---------------|-----------|-----------|
| `.camera` | AVFoundation | `NSCameraUsageDescription` |
| `.microphone` | AVFoundation | `NSMicrophoneUsageDescription` |
| `.photoLibrary` | Photos | `NSPhotoLibraryUsageDescription` |
| `.locationWhenInUse` | CoreLocation | `NSLocationWhenInUseUsageDescription` |
| `.contacts` | Contacts | `NSContactsUsageDescription` |
| `.notifications` | UserNotifications | — (не требует plist) |

## Использование в модулях

### Проверка статуса
```swift
let status = permissionsManager.status(for: .camera)
if status.isGranted {
    // Разрешение есть — используй функцию
}
```

### Запрос разрешения
```swift
let status = permissionsManager.status(for: .camera)
if status.canRequest {
    let result = await permissionsManager.request(.camera)
    if result.isGranted {
        // Разрешение получено
    } else {
        // Отказано — предложи открыть настройки
    }
} else if status.isGranted {
    // Уже есть
} else {
    // Отказано ранее — открой настройки
    permissionsManager.openSettings()
}
```

### Полный паттерн (рекомендуемый)
```swift
func handleCameraAction() {
    Task { @MainActor [weak self] in
        guard let self, let permissionsManager else { return }
        let status = permissionsManager.status(for: .camera)
        let resolved: PermissionStatus
        if status.canRequest {
            resolved = await permissionsManager.request(.camera)
        } else {
            resolved = status
        }
        if resolved.isGranted {
            openCamera()
        } else {
            showPermissionDeniedAlert()
        }
    }
}
```

### Инъекция в модуль
```swift
// В Module.build()
func build(permissionsManager: any PermissionsProviding) -> BaseViewController { ... }

// В RouteRegistry
case .featureName:
    let module = FeatureNameModule(...)
    return module.build(permissionsManager: appAssembly.permissionsManager)

// В Presenter/ViewModel — храни как зависимость
private let permissionsManager: any PermissionsProviding
```

## PermissionStatus helpers

```swift
status.isGranted   // true для .authorized и .limited
status.canRequest  // true только для .notDetermined
```

## Добавление нового permission

### Шаг 1: Добавь case в PermissionType

```swift
// PermissionType.swift
enum PermissionType {
    case camera
    case microphone
    case photoLibrary
    case locationWhenInUse
    case contacts
    case notifications
    case calendar          // ← НОВЫЙ

    var plistKey: String? {
        switch self {
        // ... существующие
        case .calendar: return "NSCalendarsFullAccessUsageDescription"
        }
    }
}
```

### Шаг 2: Добавь проверку статуса в PermissionsManager

```swift
// PermissionsManager.swift — в методе status(for:)
case .calendar:
    return EKEventStore.authorizationStatus(for: .event).asPermissionStatus
```

### Шаг 3: Добавь запрос разрешения

```swift
// PermissionsManager.swift — в методе request(_:) async
case .calendar:
    return await requestCalendar()

// Приватный метод
private func requestCalendar() async -> PermissionStatus {
    let store = EKEventStore()
    do {
        let granted = try await store.requestFullAccessToEvents()
        return granted ? .authorized : .denied
    } catch {
        return .denied
    }
}
```

### Шаг 4: Добавь маппинг статуса

```swift
// Extension для фреймворка
extension EKAuthorizationStatus {
    var asPermissionStatus: PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .fullAccess:    return .authorized
        case .writeOnly:     return .limited
        case .denied:        return .denied
        case .restricted:    return .restricted
        @unknown default:    return .denied
        }
    }
}
```

### Шаг 5: Добавь import

```swift
import EventKit  // в начало PermissionsManager.swift
```

### Шаг 6: Обнови Info.plist

Добавь ключ с описанием на всех поддерживаемых языках:
```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>Приложение запрашивает доступ к календарю для...</string>
```

## Чеклист

- [ ] Case добавлен в `PermissionType`
- [ ] `plistKey` заполнен (кроме notifications)
- [ ] `status(for:)` обрабатывает новый case
- [ ] `request(_:)` обрабатывает новый case
- [ ] Приватный метод `request{Name}()` реализован с `async`
- [ ] Extension `asPermissionStatus` для маппинга фреймворкового статуса
- [ ] Import фреймворка добавлен
- [ ] Info.plist обновлён с описанием на нужных языках
- [ ] Протокол `PermissionsProviding` **не изменён** (он generic)

## Gotchas

- `PermissionsManager` имеет **дедупликацию запросов** через `inFlightRequests` — повторный запрос того же permission ожидает завершения текущего, а не создаёт новый
- Location использует `CLLocationManagerDelegate` + `CheckedContinuation` — уникальный паттерн
- Notifications: статус **кешируется** в `notificationStatus`, т.к. `UNUserNotificationCenter` не имеет синхронного API
- `PermissionsProviding` принимает `any PermissionsProviding` — для тестируемости через mock
- Статусы обновляются при `sysDidBecomeActiveNotification` — пользователь мог изменить в Settings
- `.limited` считается `.isGranted = true` (например, PHPhotoLibrary limited access)
