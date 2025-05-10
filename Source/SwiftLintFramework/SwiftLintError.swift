import Foundation

package enum SwiftLintError: LocalizedError {
    case usageError(description: String)

    package var errorDescription: String? {
        switch self {
        case .usageError(let description):
            return description
        }
    }
}
