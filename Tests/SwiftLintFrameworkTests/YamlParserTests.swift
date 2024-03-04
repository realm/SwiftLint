@testable import SwiftLintFramework
import XCTest

final class YamlParserTests: SwiftLintTestCase {
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
        checkError(Issue.yamlParsing("2:1: error: parser: did not find expected <document start>:\na\n^")) {
            _ = try YamlParser.parse("|\na", env: [:])
        }
    }

    func testTreatAllEnvVarsAsStringsWithoutCasting() throws {
        let env = [
            "INT": "1",
            "FLOAT": "1.0",
            "BOOL": "true",
            "STRING": "string",
        ]
        let string = """
            int: ${INT}
            float: ${FLOAT}
            bool: ${BOOL}
            string: ${STRING}
            """

        let result = try YamlParser.parse(string, env: env)

        XCTAssertEqual(result["int"] as? String, "1")
        XCTAssertEqual(result["float"] as? String, "1.0")
        XCTAssertEqual(result["bool"] as? String, "true")
        XCTAssertEqual(result["string"] as? String, "string")
    }

    func testRespectCastsOnEnvVars() throws {
        let env = [
            "INT": "1",
            "FLOAT": "1.0",
            "BOOL": "true",
            "STRING": "string",
        ]
        let string = """
            int: !!int ${INT}
            float: !!float ${FLOAT}
            bool: !!bool ${BOOL}
            string: !!str ${STRING}
            """

        let result = try YamlParser.parse(string, env: env)

        XCTAssertEqual(result["int"] as? Int, 1)
        XCTAssertEqual(result["float"] as? Double, 1.0)
        XCTAssertEqual(result["bool"] as? Bool, true)
        XCTAssertEqual(result["string"] as? String, "string")
    }
}
