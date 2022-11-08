import SwiftLintFramework
import XCTest

// swiftlint:disable:next balanced_xctest_lifecycle
open class SwiftLintTestCase: XCTestCase {
    override open class func setUp() {
        super.setUp()
        RuleRegistry.registerAllRulesOnce()
    }
}
