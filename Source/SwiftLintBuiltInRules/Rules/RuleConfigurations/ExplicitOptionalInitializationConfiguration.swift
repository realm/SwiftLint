import SwiftLintCore

@AutoConfigParser
struct ExplicitOptionalInitializationConfiguration: SeverityBasedRuleConfiguration {
  typealias Parent = ExplicitOptionalInitializationRule

  @AcceptableByConfigurationElement
  enum Style: String {
    case always
    case never
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "style")
  private(set) var style: Style = .never
}
