private let _registerAllRulesOnceImpl: Void = {
    RuleRegistry.shared.register(rules: builtInRules + extraRules())
}()

/// Container to register and look up SwiftLint rules.
public final class RuleRegistry {
    fileprivate var registeredRules = [Rule.Type]()

    /// Shared rule registry instance.
    public static let shared = RuleRegistry()

    /// Rule list associated with this registry. Lazily created, and
    /// immutable once looked up.
    ///
    /// - note: Adding registering more rules after this was first
    ///         accessed will not work.
    public private(set) lazy var list = RuleList(rules: registeredRules)

    private init() {}

    /// Register rules.
    ///
    /// - parameter rules: The rules to register.
    public func register(rules: [Rule.Type]) {
        registeredRules.append(contentsOf: rules)
    }

    /// Look up a rule for a given ID.
    ///
    /// - parameter id: The ID for the rule to look up.
    ///
    /// - returns: The rule matching the specified ID, if one was found.
    public func rule(forID id: String) -> Rule.Type? {
        return list.list[id]
    }

    /// Register all rules. Should only be called once before any SwiftLint code is executed.
    public static func registerAllRulesOnce() {
        _ = _registerAllRulesOnceImpl
    }
}
