public protocol RuleConfiguration {
    var consoleDescription: String { get }

    mutating func apply(configuration: Any) throws
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool
}

public extension RuleConfiguration where Self: Equatable {
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        return self == ruleConfiguration as? Self
    }
}
