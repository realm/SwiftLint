import Foundation

enum SwiftLintError: LocalizedError {
    case usageError(description: String)

    var errorDescription: String? {
        switch self {
        case .usageError(let description):
            return description
        }
    }
}
