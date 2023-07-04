import SwiftLintCore

typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<DiscouragedObjectLiteralRule>

struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration, Equatable {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "image_literal")
    private(set) var imageLiteral = true
    @ConfigurationElement(key: "color_literal")
    private(set) var colorLiteral = true

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        imageLiteral = configuration[$imageLiteral] as? Bool ?? true
        colorLiteral = configuration[$colorLiteral] as? Bool ?? true

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
