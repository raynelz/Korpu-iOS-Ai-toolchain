---
name: x-service-layer
description: Создай новый сервис для работы с API в проекте Korpu. Используй при добавлении нового GraphQL сервиса, REST-обёртки, или сетевого слоя для фичи. Триггер — пользователь просит создать сервис, добавить API-вызов, обернуть GraphQL запрос, создать сетевой слой для модуля.
---

# Service Layer Generator

Создай сервис для работы с API (Apollo GraphQL / REST) в проекте Korpu.

## Архитектура сервисов

```
KOGraphQLService (protocol)  — Apollo GraphQL: fetch(), perform(), subscribe()
KORestService (protocol)     — REST: multipart upload и т.д.
  └── {Feature}Service       — конкретный сервис

AppAssembly                  — DI-контейнер, регистрация через lazy var
RouteRegistry                — инъекция сервисов в модули
```

**Файлы:**
- Сервисы: `Korpu/Services/{FeatureName}Service.swift`
- DI: `Korpu/App/AppAssembly.swift`
- GraphQL операции: `Korpu/API/*.graphql`
- Сгенерированный код: `SharedAPI/Generated/`

## Шаг 1: Создай Protocol (опционально, для тестируемости)

```swift
import SharedAPI

protocol {FeatureName}ServiceProtocol {
    func fetchItems(cachePolicy: CachePolicy) async throws -> [ItemModel]
    func createItem(input: CreateItemInput) async throws -> ItemModel
    func deleteItem(id: Int) async throws -> Bool
}
```

## Шаг 2: Создай Service

```swift
import Apollo
import Foundation
import SharedAPI

final class {FeatureName}Service: KOGraphQLService, {FeatureName}ServiceProtocol {

    // MARK: - KOGraphQLService

    let tokenProvider: any TokenProvider
    let endpoints: ApolloEndpoints

    // MARK: - Init

    init(tokenProvider: any TokenProvider, endpoints: ApolloEndpoints) {
        self.tokenProvider = tokenProvider
        self.endpoints = endpoints
    }

    // MARK: - Queries

    func fetchItems(
        cachePolicy: CachePolicy = .fetchIgnoringCacheData
    ) async throws -> [ItemModel] {
        let query = GetItemsQuery()
        do {
            let data = try await fetch(query, cachePolicy: cachePolicy)
            return data.getItems.map { ItemModel(from: $0) }
        } catch {
            throw error.toKOError(domain: .custom("{featureName}"))
        }
    }

    func fetchItem(
        id: Int,
        cachePolicy: CachePolicy = .fetchIgnoringCacheData
    ) async throws -> ItemModel {
        let query = GetItemQuery(id: id)
        do {
            let data = try await fetch(query, cachePolicy: cachePolicy)
            guard let item = data.getItem else {
                throw KOError(domain: .custom("{featureName}"), message: "Item not found")
            }
            return ItemModel(from: item)
        } catch let error as KOError {
            throw error
        } catch {
            throw error.toKOError(domain: .custom("{featureName}"))
        }
    }

    // MARK: - Mutations

    func createItem(input: CreateItemInput) async throws -> ItemModel {
        let mutation = CreateItemMutation(input: input)
        do {
            let data = try await perform(mutation)
            return ItemModel(from: data.createItem)
        } catch {
            throw error.toKOError(domain: .custom("{featureName}"))
        }
    }

    func deleteItem(id: Int) async throws -> Bool {
        let mutation = DeleteItemMutation(id: id)
        do {
            let data = try await perform(mutation)
            return data.deleteItem
        } catch {
            throw error.toKOError(domain: .custom("{featureName}"))
        }
    }

    // MARK: - Subscriptions

    func subscribeToItemUpdates(id: Int) -> AsyncThrowingStream<ItemUpdateSubscription.Data, Error> {
        let subscription = ItemUpdateSubscription(id: id)
        return subscribe(subscription)
    }
}
```

## Шаг 3: Зарегистрируй в AppAssembly

Открой `Korpu/App/AppAssembly.swift` и добавь lazy var:

```swift
// MARK: - {FeatureName}

private(set) lazy var {featureName}Service: {FeatureName}Service = {
    {FeatureName}Service(tokenProvider: tokenProvider, endpoints: endpoints)
}()
```

Если сервису нужны дополнительные зависимости:

```swift
private(set) lazy var {featureName}Service: {FeatureName}Service = {
    {FeatureName}Service(
        tokenProvider: tokenProvider,
        endpoints: endpoints,
        sessionManager: sessionManager
    )
}()
```

## Шаг 4: Инъекция в модуль через RouteRegistry

В `RouteRegistry.swift`:

```swift
case .featureName:
    let module = FeatureNameModule(route: route, router: router, mainNavController: navController)
    return module.build(
        featureNameService: appAssembly.featureNameService
    )
```

## Паттерны Apollo GraphQL

### Fetch (query)
```swift
let data = try await fetch(query, cachePolicy: cachePolicy)
```

### Perform (mutation)
```swift
let data = try await perform(mutation)
```

### Subscribe (subscription)
```swift
func subscribeToUpdates() -> AsyncThrowingStream<SomeSubscription.Data, Error> {
    return subscribe(SomeSubscription())
}
```

### GraphQL Nullability
```swift
// Optional → GraphQLNullable
let optionalValue: GraphQLNullable<String> = value.isEmpty ? .none : .some(value)
let optionalInt: GraphQLNullable<Int> = id.map { .some($0) } ?? .none

// Для массивов
let usersValue: GraphQLNullable<[Int]> = userIds.isEmpty ? .none : .some(userIds)
```

### Cache Policy
```swift
// Стандартные варианты
.fetchIgnoringCacheData     // Всегда с сервера (по умолчанию)
.returnCacheDataElseFetch   // Кеш, если есть
.returnCacheDataAndFetch    // Кеш + обновление с сервера
```

## Обработка ошибок

### Стандартный паттерн
```swift
do {
    let data = try await fetch(query)
    return processData(data)
} catch {
    throw error.toKOError(domain: .custom("{featureName}"))
}
```

### Сохранение KOError metadata
```swift
do {
    // ...
} catch let error as KOError {
    // Перебросить с сохранением metadata
    var mapped = KOError(domain: .custom("{featureName}"), message: error.message, metadata: error.metadata)
    mapped.additionalErrors = error.additionalErrors
    throw mapped
} catch {
    throw error.toKOError(domain: .custom("{featureName}"))
}
```

## REST Service (для upload)

Если сервис также работает с REST (multipart upload):

```swift
final class {FeatureName}Service: KOGraphQLService, KORestService, {FeatureName}ServiceProtocol {
    let tokenProvider: any TokenProvider
    let endpoints: ApolloEndpoints

    func uploadMedia(
        fileURL: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> UploadMediaResponse {
        // REST upload через KORestService
    }
}
```

## Чеклист

- [ ] Сервис реализует `KOGraphQLService` (и `KORestService` при необходимости)
- [ ] Свойства `tokenProvider` и `endpoints` объявлены и инициализированы
- [ ] Все методы `async throws` (не completion handler)
- [ ] Ошибки трансформируются через `error.toKOError(domain:)`
- [ ] `KOError` с metadata корректно перебрасывается
- [ ] Сервис зарегистрирован в `AppAssembly` как `lazy var`
- [ ] Инъекция в модуль через `RouteRegistry`
- [ ] Cache policy поддерживается для query-методов
- [ ] `Logger.log()` для диагностики, не `print()`

## Gotchas

- `endpoints` в `AppAssembly` — computed property из `appSettingsManager.appSettings.apolloEndpoints`
- Все сервисы получают одни и те же `tokenProvider` и `endpoints` — это стандарт
- `fetch()` и `perform()` предоставляются `KOGraphQLService` — не нужно реализовывать самому
- `subscribe()` возвращает `AsyncThrowingStream` — подписчик должен итерировать через `for try await`
- GraphQL операции (.graphql файлы) живут в `Korpu/API/`, сгенерированный код — в `SharedAPI/Generated/`
- После добавления нового .graphql файла нужно запустить кодогенерацию: `./apollo-ios-cli generate --path apollo-codegen-config.json`
- `CommentsService` создаётся с дополнительным параметром `configuration:` — не все сервисы одинаковы
