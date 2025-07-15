import SwiftLintCore

@AutoConfigParser
struct ExplicitOptionalInitializationConfiguration: RuleConfiguration {
  typealias Parent = ExplicitOptionalInitializationRule

  @AcceptableByConfigurationElement
  enum Enforcement: String {
    case always
    case never
  }

  @ConfigurationElement(key: "severity")
  private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
  @ConfigurationElement(key: "enforce")
  private(set) var enforcement: Enforcement = .always
}
