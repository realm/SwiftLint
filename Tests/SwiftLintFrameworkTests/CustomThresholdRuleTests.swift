import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class CustomThresholdRuleTests: XCTestCase {
    func testCustomRuleConfigurationSetsCorrectly() {
        let configDict = [
            "my_custom_threshold_rule": [
                "name": "MyCustomThresholdRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error"
            ]
        ]
        var comp = ThresholdRegexConfiguration(identifier: "my_custom_threshold_rule")
        comp.name = "MyCustomThresholdRule"
        comp.message = "Message"
        comp.regex = regex("regex")
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.matchKinds = Set([SyntaxKind.comment])
        var compRules = CustomThresholdRulesConfiguration()
        compRules.customThresholdRuleConfigurations = [comp]
        do {
            var configuration = CustomThresholdRulesConfiguration()
            try configuration.apply(configuration: configDict)
            XCTAssertEqual(configuration, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }
}
