/// A task-local value that holds the identifier of the currently executing rule.
/// This allows SourceKit request handling to determine if the current rule
/// is a SourceKitFreeRule without modifying function signatures throughout the codebase.
public enum CurrentRule {
    /// The Rule ID for the currently executing rule.
    @TaskLocal public static var identifier: String?

    /// Allows specific SourceKit requests to be made outside of rule execution context.
    /// This should only be used for essential operations like getting the Swift version.
    @TaskLocal public static var allowSourceKitRequestWithoutRule = false
}
