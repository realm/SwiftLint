/// Container to register and look up SwiftLint rules.
public final class RuleRegistry: @unchecked Sendable {
    private var registeredRules = [any Rule.Type]()

    /// Shared rule registry instance.
    public static let shared = RuleRegistry()

    /// Rule list associated with this registry. Lazily created, and
    /// immutable once looked up.
    ///
    /// - note: Adding registering more rules after this was first
    ///         accessed will not work.
    public private(set) var list: RuleList! // swiftlint:disable:this implicitly_unwrapped_optional

    private init() { /* To guarantee that this is singleton. */ }

    /// Register rules.
    ///
    /// - parameter rules: The rules to register.
    public func register(rules: [any Rule.Type]) {
        if list != nil {
            queuedFatalError("Rules cannot be registered after the rule list has been accessed.")
        }
        list = RuleList(rules: rules)
    }

    /// Look up a rule for a given ID.
    ///
    /// - parameter id: The ID for the rule to look up.
    ///
    /// - returns: The rule matching the specified ID, if one was found.
    public func rule(forID id: String) -> (any Rule.Type)? {
        list.list[id]
    }
}
