import Foundation

/// Screen state for one async value. An enum instead of several Bools, so
/// invalid combinations (loading + error) cannot exist.
enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(message: String)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    var isLoaded: Bool { value != nil }
}

extension Loadable: Equatable where Value: Equatable {}
