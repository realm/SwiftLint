import SwiftLintCore

@AutoConfigParser
struct ImplicitReturnConfiguration: SeverityBasedRuleConfiguration {
    @AcceptableByConfigurationElement
    enum ReturnKind: String, CaseIterable, Comparable {
        case closure
        case function
        case getter
        case `subscript`
        case initializer

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    static let defaultIncludedKinds = Set(ReturnKind.allCases)

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "included")
    private(set) var includedKinds = Self.defaultIncludedKinds
    @ConfigurationElement(key: "check_if_and_switch_expressions")
    private(set) var checkIfAndSwitchExpressions = false

    init(includedKinds: Set<ReturnKind> = Self.defaultIncludedKinds, checkIfAndSwitchExpressions: Bool = false) {
        self.includedKinds = includedKinds
        self.checkIfAndSwitchExpressions = checkIfAndSwitchExpressions
    }

    func isKindIncluded(_ kind: ReturnKind) -> Bool {
        includedKinds.contains(kind)
    }
}
