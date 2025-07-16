import TestHelpers

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

final class ExplicitOptionalInitializationTests: SwiftLintTestCase {
  func testExplicitOptionalInitialization() {
    verifyRule(
      ExplicitOptionalInitializationRule.description
    )
  }
}
