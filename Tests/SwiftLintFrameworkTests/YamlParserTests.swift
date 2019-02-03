@testable import SwiftLintFramework
import XCTest

class YamlParserTests: XCTestCase {
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

    func testParseDuplicatedKeysInRootThrows() {
        checkError(YamlParserError.yamlParsing("Duplicated keys found: 'excluded'.")) {
            let yaml = """
                      excluded:
                        - foo
                      excluded:
                        - bar
                      """
            _ = try YamlParser.parse(yaml, env: [:])
        }
    }

    func testParseDuplicatedKeysInNestedFieldThrows() {
        let message = "Duplicated keys found: 'minimum_length'. Found inside keypath 'number_separator'."
        checkError(YamlParserError.yamlParsing(message)) {
            let yaml = """
                      number_separator:
                        minimum_length: 5
                        minimum_length: 3
                      """
            _ = try YamlParser.parse(yaml, env: [:])
        }
    }
}
