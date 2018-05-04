public protocol RuleConfiguration {
    var consoleDescription: String { get }

    mutating func apply(configuration: Any) throws
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool
}

extension RuleConfiguration {
    internal var cacheDescription: String {
        return (self as? CacheDescriptionProvider)?.cacheDescription ?? consoleDescription
    }
}

public extension RuleConfiguration where Self: Equatable {
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        return self == ruleConfiguration as? Self
    }
}
