/// All the possible rule kinds (categories).
public enum RuleKind: String, Codable {
    /// Describes rules that validate Swift source conventions.
    case lint
    /// Describes rules that validate common practices in the Swift community.
    case idiomatic
    /// Describes rules that validate stylistic choices.
    case style
    /// Describes rules that validate magnitudes or measurements of Swift source.
    case metrics
    /// Describes rules that validate that code patterns with poor performance are avoided.
    case performance
}
