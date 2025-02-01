import Testing

@testable import SwiftLintFramework

@Suite
struct YamlParserTests {
    @Test
    func parseEmptyString() throws {
        let result = try YamlParser.parse("", env: [:])
        #expect(result.isEmpty, "Parsing empty YAML string should succeed")
    }

    @Test
    func parseValidString() throws {
        let result = try YamlParser.parse("a: 1\nb: 2", env: [:])
        #expect(result.count == 2, "Parsing valid YAML string should succeed")
    }

    @Test
    func parseReplacesEnvVar() throws {
        let env = ["PROJECT_NAME": "SwiftLint"]
        let string = "excluded:\n  - ${PROJECT_NAME}/Extensions"
        let result = try YamlParser.parse(string, env: env)

        #expect(result["excluded"] as? [String] ?? [] == ["SwiftLint/Extensions"])
    }

    @Test
    func parseTreatNoAsString() throws {
        let string = "excluded:\n  - no"
        let result = try YamlParser.parse(string, env: [:])

        #expect(result["excluded"] as? [String] ?? [] == ["no"])
    }

    @Test
    func parseTreatYesAsString() throws {
        let string = "excluded:\n  - yes"
        let result = try YamlParser.parse(string, env: [:])

        #expect(result["excluded"] as? [String] ?? [] == ["yes"])
    }

    @Test
    func parseTreatOnAsString() throws {
        let string = "excluded:\n  - on"
        let result = try YamlParser.parse(string, env: [:])

        #expect(result["excluded"] as? [String] ?? [] == ["on"])
    }

    @Test
    func parseTreatOffAsString() throws {
        let string = "excluded:\n  - off"
        let result = try YamlParser.parse(string, env: [:])

        #expect(result["excluded"] as? [String] ?? [] == ["off"])
    }

    @Test
    func parseInvalidStringThrows() {
        #expect(throws: Issue.yamlParsing("2:1: error: parser: did not find expected <document start>:\na\n^")) {
            _ = try YamlParser.parse("|\na", env: [:])
        }
    }

    @Test
    func treatAllEnvVarsAsStringsWithoutCasting() throws {
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

        #expect(result["int"] as? String == "1")
        #expect(result["float"] as? String == "1.0")
        #expect(result["bool"] as? String == "true")
        #expect(result["string"] as? String == "string")
    }

    @Test
    func respectCastsOnEnvVars() throws {
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

        #expect(result["int"] as? Int == 1)
        #expect(result["float"] as? Double == 1.0)
        #expect(result["bool"] as? Bool == true)
        #expect(result["string"] as? String == "string")
    }
}
