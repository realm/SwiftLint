import SwiftLintCore

@AutoApply
struct ImplicitReturnConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ImplicitReturnRule

    @MakeAcceptableByConfigurationElement
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

    init(includedKinds: Set<ReturnKind> = Self.defaultIncludedKinds) {
        self.includedKinds = includedKinds
    }

    func isKindIncluded(_ kind: ReturnKind) -> Bool {
        return self.includedKinds.contains(kind)
    }
}
