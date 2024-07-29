import SwiftLintCore

@AutoConfigParser
struct IdentifierNameConfiguration: RuleConfiguration {
    typealias Parent = IdentifierNameRule

    private static let defaultOperators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&"]

    @ConfigurationElement(inline: true)
    private(set) var nameConfiguration = NameConfiguration<Parent>(minLengthWarning: 3,
                                                                   minLengthError: 2,
                                                                   maxLengthWarning: 40,
                                                                   maxLengthError: 60,
                                                                   excluded: ["id"])

    @ConfigurationElement(key: "additional_operators", postprocessor: { $0.formUnion(Self.defaultOperators) })
    private(set) var additionalOperators = Set<String>()
}
