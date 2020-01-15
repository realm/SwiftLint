import SwiftLintFramework
import XCTest

class SortedImportsRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        verifyRule(SortedImportsRule.description, commentDoesntViolate: true,
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testWithTestableImportsTop() {
        let triggeringExamples = [
            Example("import AAA\nimport BBB\n@testable import CCC\nimport DDD"),
            Example("@testable import BBB\n@testable import AAA\nimport CCC\nimport DDD")
        ]
        let nonTriggeringExamples = [
            Example("@testable import CCC\nimport AAA\nimport BBB\nimport DDD"),
            Example("@testable import AAA\n@testable import BBB\nimport CCC\nimport DDD")
        ]
        let corrections = [
            Example("import AAA\nimport BBB\n@testable import CCC\nimport DDD"):
                Example("@testable import CCC\nimport AAA\nimport BBB\nimport DDD"),
            Example("@testable import BBB\n@testable import AAA\nimport CCC\nimport DDD"):
                Example("@testable import AAA\n@testable import BBB\nimport CCC\nimport DDD")
        ]

        let description = SortedImportsRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["testable_imports": "top"],
                   testMultiByteOffsets: false, testShebang: false)
    }

    func testWithTestableImportsBottom() {
        let triggeringExamples = [
            Example("import AAA\nimport BBB\n@testable import CCC\nimport DDD"),
            Example("import CCC\nimport DDD\n@testable import BBB\n@testable import AAA")
        ]
        let nonTriggeringExamples = [
            Example("import AAA\nimport BBB\nimport DDD\n@testable import CCC"),
            Example("import CCC\nimport DDD\n@testable import AAA\n@testable import BBB")
        ]
        let corrections = [
            Example("import AAA\nimport BBB\n@testable import CCC\nimport DDD"):
                Example("import AAA\nimport BBB\nimport DDD\n@testable import CCC"),
            Example("import CCC\nimport DDD\n@testable import BBB\n@testable import AAA"):
                Example("import CCC\nimport DDD\n@testable import AAA\n@testable import BBB")
        ]

        let description = SortedImportsRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["testable_imports": "bottom"],
                   testMultiByteOffsets: false, testShebang: false)
    }
}
