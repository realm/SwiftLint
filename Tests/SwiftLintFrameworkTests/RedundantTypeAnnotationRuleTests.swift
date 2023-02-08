@testable import SwiftLintBuiltInRules
import XCTest

class RedundantTypeAnnotationRuleTests: XCTestCase {
    func testRedundantTypeAnnotationRuleDoesIgnoreBooleans() {
        let nonTriggeringExamples = [
            Example("let abc: Bool = true\n"),
            Example("let abc: Bool = false\n"),
            Example("var abc: Bool = true\n"),
            Example("var abc: Bool = false\n"),
            Example("lazy var abc: Bool = true\n"),
            Example("lazy var abc: Bool = false\n"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let abc: Bool = true
              }
            }
            """)
        ]
        let triggeringExamples = [
            Example("var url↓:URL=URL()"),
            Example("var url↓:URL = URL(string: \"\")"),
            Example("var url↓: URL = URL()"),
            Example("let url↓: URL = URL()"),
            Example("lazy var url↓: URL = URL()"),
            Example("let alphanumerics↓: CharacterSet = CharacterSet.alphanumerics"),
            Example("""
            class ViewController: UIViewController {
              func someMethod() {
                let myVar↓: Int = Int(5)
              }
            }
            """),
            Example("""
            enum Direction {
                case up
                case down
            }

            var direction↓: Direction = Direction.up
            """)
        ]
        let description = RedundantTypeAnnotationRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: RedundantTypeAnnotationRule.description.corrections)
        verifyRule(description, ruleConfiguration: ["ignore_booleans": true])
    }

    func testRedundantTypeAnnotationDoesNotIgnoreBooleans() {
        let triggeringExamples = [
            Example("let abc: Bool = true\n"),
            Example("let abc: Bool = false\n"),
            Example("var abc: Bool = true\n"),
            Example("var abc: Bool = false\n")
        ]
        let description = RedundantTypeAnnotationRule.description
            .with(nonTriggeringExamples: RedundantTypeAnnotationRule.description.nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: RedundantTypeAnnotationRule.description.corrections)
        verifyRule(description, ruleConfiguration: ["ignore_booleans": false])
    }
}
