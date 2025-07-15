import TestHelpers

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

final class ExplicitOptionalInitializationTests: SwiftLintTestCase {
  func testExplicitOptionalInitializationAlways() {
    verifyRule(
      ExplicitOptionalInitializationRule.description,
      ruleConfiguration: ["style": "always"]
    )
  }

  func testExplicitOptionalInitializationNever() {
    verifyRule(
      ExplicitOptionalInitializationRule.description,
      ruleConfiguration: ["style": "never"]
    )
  }
}
