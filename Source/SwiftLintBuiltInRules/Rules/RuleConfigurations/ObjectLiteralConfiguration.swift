import SwiftLintCore

typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<DiscouragedObjectLiteralRule>

@AutoConfigParser
struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "image_literal")
    private(set) var imageLiteral = true
    @ConfigurationElement(key: "color_literal")
    private(set) var colorLiteral = true
}
