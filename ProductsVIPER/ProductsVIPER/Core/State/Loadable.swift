import Foundation

/// The state of asynchronously loading a single value.
///
/// Instead of several independent properties (`isLoading`, `error`, `data`) that
/// can form an invalid combination (for example `isLoading == true` AND `error != nil`),
/// the enum makes invalid states unrepresentable ("make impossible states impossible").
/// The `switch` in the View is exhaustive — the compiler forces us to cover every case.
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
