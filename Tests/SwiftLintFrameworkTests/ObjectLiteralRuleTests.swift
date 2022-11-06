@testable import SwiftLintBuiltInRules
import SwiftLintFramework

class ObjectLiteralRuleTests: SwiftLintTestCase {
    // MARK: - Instance Properties
    private let imageLiteralTriggeringExamples = ["", ".init"].flatMap { (method: String) -> [Example] in
        ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
            [
                Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")")
            ]
        }
    }

    private let colorLiteralTriggeringExamples = ["", ".init"].flatMap { (method: String) -> [Example] in
        ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
            [
                Example("let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)"),
                Example("let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)"),
                Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)")
            ]
        }
    }

    private var allTriggeringExamples: [Example] {
        return imageLiteralTriggeringExamples + colorLiteralTriggeringExamples
    }

    // MARK: - Test Methods
    func testObjectLiteralWithImageLiteral() {
        // Verify ObjectLiteral rule for when image_literal is true.
        let baseDescription = ObjectLiteralRule.description
        let nonTriggeringColorLiteralExamples = colorLiteralTriggeringExamples.removingViolationMarkers()
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringColorLiteralExamples

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: imageLiteralTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": true, "color_literal": false])
    }

    func testObjectLiteralWithColorLiteral() {
        // Verify ObjectLiteral rule for when color_literal is true.
        let baseDescription = ObjectLiteralRule.description
        let nonTriggeringImageLiteralExamples = imageLiteralTriggeringExamples.removingViolationMarkers()
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + nonTriggeringImageLiteralExamples

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: colorLiteralTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": false, "color_literal": true])
    }

    func testObjectLiteralWithImageAndColorLiteral() {
        // Verify ObjectLiteral rule for when image_literal & color_literal are true.
        let description = ObjectLiteralRule.description.with(triggeringExamples: allTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["image_literal": true, "color_literal": true])
    }
}
