import Foundation
import Testing
@testable import ProductsClean

struct AsyncCacheTests {
    @Test func concurrentRequestsForSameKeyAreDeduplicated() async throws {
        let cache = AsyncCache<Int, String>()
        let counter = Counter()
        let loader: @Sendable () async throws -> String = {
            await counter.increment()
            try await Task.sleep(for: .milliseconds(20))
            return "value"
        }

        async let first = cache.value(for: 1, loader: loader)
        async let second = cache.value(for: 1, loader: loader)
        let results = try await [first, second]

        #expect(results == ["value", "value"])
        #expect(await counter.value == 1)
    }

    @Test func failuresAreNotCached() async throws {
        let cache = AsyncCache<Int, String>()
        let counter = Counter()

        await #expect(throws: NetworkError.self) {
            try await cache.value(for: 1) {
                await counter.increment()
                throw NetworkError.httpStatus(500)
            }
        }
        let value = try await cache.value(for: 1) {
            await counter.increment()
            return "recovered"
        }

        #expect(value == "recovered")
        #expect(await counter.value == 2)
    }

    @Test func expiredValuesAreReloaded() async throws {
        let cache = AsyncCache<Int, Int>(timeToLive: .zero)
        let counter = Counter()
        let loader: @Sendable () async throws -> Int = {
            await counter.increment()
            return await counter.value
        }

        _ = try await cache.value(for: 1, loader: loader)
        let second = try await cache.value(for: 1, loader: loader)

        #expect(second == 2)
    }
}
