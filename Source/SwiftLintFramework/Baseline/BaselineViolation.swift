import Foundation

/// A violation saved in a baseline record that future linting can be compared against.
struct BaselineViolation: Equatable {
    /// The identifier for the violation.
    let ruleIdentifier: String
    /// The location of the violation.
    let location: String
    /// The description of the violation.
    let reason: String
}
