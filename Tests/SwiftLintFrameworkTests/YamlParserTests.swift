@testable import SwiftLintFramework
import XCTest

class YamlParserTests: SwiftLintTestCase {
    func testParseEmptyString() {
        XCTAssertEqual((try YamlParser.parse("", env: [:])).count, 0,
                       "Parsing empty YAML string should succeed")
    }

    func testParseValidString() {
        XCTAssertEqual(try YamlParser.parse("a: 1\nb: 2", env: [:]).count, 2,
                       "Parsing valid YAML string should succeed")
    }

    func testParseReplacesEnvVar() throws {
        let env = ["PROJECT_NAME": "SwiftLint"]
        let string = "excluded:\n  - ${PROJECT_NAME}/Extensions"
        let result = try YamlParser.parse(string, env: env)

        XCTAssertEqual(result["excluded"] as? [String] ?? [], ["SwiftLint/Extensions"])
    }

    func testParseTreatNoAsString() throws {
        let string = "excluded:\n  - no"
        let result = try YamlParser.parse(string, env: [:])

        XCTAssertEqual(result["excluded"] as? [String] ?? [], ["no"])
    }

    func testParseTreatYesAsString() throws {
        let string = "excluded:\n  - yes"
        let result = try YamlParser.parse(string, env: [:])

        XCTAssertEqual(result["excluded"] as? [String] ?? [], ["yes"])
    }

    func testParseTreatOnAsString() throws {
        let string = "excluded:\n  - on"
        let result = try YamlParser.parse(string, env: [:])

        XCTAssertEqual(result["excluded"] as? [String] ?? [], ["on"])
    }

    func testParseTreatOffAsString() throws {
        let string = "excluded:\n  - off"
        let result = try YamlParser.parse(string, env: [:])

        XCTAssertEqual(result["excluded"] as? [String] ?? [], ["off"])
    }

    func testParseInvalidStringThrows() {
        checkError(YamlParserError.yamlParsing("2:1: error: parser: did not find expected <document start>:\na\n^")) {
            _ = try YamlParser.parse("|\na", env: [:])
        }
    }
}
