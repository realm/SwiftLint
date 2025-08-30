/// This allows SourceKit request handling to determine certain properties without
/// modifying function signatures throughout the codebase.
public enum CurrentRule {
    /// A task-local value that holds the identifier of the currently executing rule, e.g., to check whether the rule
    /// is allowed to make SourceKit requests.
    @TaskLocal public static var identifier: String?

    /// Allows specific SourceKit requests to be made outside of rule execution context.
    /// This should only be used for essential operations like getting the Swift version.
    @TaskLocal public static var allowSourceKitRequestWithoutRule = false
}
