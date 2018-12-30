import Foundation
import SwiftLintFramework
import XCTest

class RuleDescriptionTests: XCTestCase {
    func testCodableWithMissingValues() throws {
        let json = [
            "identifier": "my_cool_rule",
            "name": "Cool Rule",
            "description": "Validates stuff",
            "kind": "style"
        ]

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try JSONSerialization.data(withJSONObject: json)
        let ruleDescription = try decoder.decode(RuleDescription.self, from: data)

        let expectedDescription = RuleDescription(identifier: "my_cool_rule", name: "Cool Rule",
                                                  description: "Validates stuff", kind: .style)

        // Comparing field by field because RuleDescription's == only checks the identifier
        XCTAssertEqual(ruleDescription.identifier, expectedDescription.identifier)
        XCTAssertEqual(ruleDescription.name, expectedDescription.name)
        XCTAssertEqual(ruleDescription.description, expectedDescription.description)
        XCTAssertEqual(ruleDescription.kind, expectedDescription.kind)
        XCTAssertEqual(ruleDescription.triggeringExamples, expectedDescription.triggeringExamples)
        XCTAssertEqual(ruleDescription.nonTriggeringExamples, expectedDescription.nonTriggeringExamples)
        XCTAssertEqual(ruleDescription.corrections, expectedDescription.corrections)
        XCTAssertEqual(ruleDescription.deprecatedAliases, expectedDescription.deprecatedAliases)
        XCTAssertEqual(ruleDescription.minSwiftVersion, expectedDescription.minSwiftVersion)
        XCTAssertEqual(ruleDescription.requiresFileOnDisk, expectedDescription.requiresFileOnDisk)
    }
}
