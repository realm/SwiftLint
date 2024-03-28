import SwiftLintCore

typealias DiscouragedObjectLiteralConfiguration = ObjectLiteralConfiguration<DiscouragedObjectLiteralRule>

@AutoApply
struct ObjectLiteralConfiguration<Parent: Rule>: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "image_literal")
    private(set) var imageLiteral = true
    @ConfigurationElement(key: "color_literal")
    private(set) var colorLiteral = true
}
