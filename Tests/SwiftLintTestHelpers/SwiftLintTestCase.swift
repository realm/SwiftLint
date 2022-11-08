import SwiftLintFramework
import XCTest

open class SwiftLintTestCase: XCTestCase {
    override open class func setUp() {
        super.setUp()
        RuleRegistry.registerAllRulesOnce()
    }
}
