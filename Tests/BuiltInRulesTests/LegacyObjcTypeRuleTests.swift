@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class LegacyObjcTypeRuleTests: SwiftLintTestCase {
    func testLegacyObjcTypeWithAllowedTypes() {
        let baseDescription = LegacyObjcTypeRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let data = NSData()"),
            Example("let number: NSNumber"),
            Example("class SLURLRequest: NSURLRequest {}"),
        ]
        let triggeringExamples = baseDescription.triggeringExamples.filter {
            !$0.code.contains("NSData") && !$0.code.contains("NSNumber") && !$0.code.contains("NSURLRequest")
        }
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_types": ["NSData", "NSNumber", "NSURLRequest"]])
    }
}
