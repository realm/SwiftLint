import Foundation

/// Represents unused or missing import statements.
enum ImportUsage {
    /// The import is unused. Range is for the entire import statement.
    case unused(module: String, range: NSRange)
    /// The file is missing an explicit import of the `module`.
    case missing(module: String)

    /// The range where the violation for this import usage should be reported.
    var violationRange: NSRange? {
        switch self {
        case .unused(_, let range):
            return range
        case .missing:
            return nil
        }
    }

    /// The reason why this import usage is a violation.
    var violationReason: String? {
        switch self {
        case .unused:
            return nil
        case .missing(let module):
            return "Missing import for referenced module '\(module)'"
        }
    }
}
