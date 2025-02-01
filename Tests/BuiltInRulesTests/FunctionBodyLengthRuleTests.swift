import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct FunctionBodyLengthRuleTests {
    @Test
    func warning() {
        let example = Example(
            """
            func f() {
                let x = 0
                let y = 1
                let z = 2
            }
            """)

        #expect(
            self.violations(example, configuration: ["warning": 2, "error": 4]) == [
                StyleViolation(
                    ruleDescription: FunctionBodyLengthRule.description,
                    severity: .warning,
                    location: Location(file: nil, line: 1, character: 1),
                    reason: """
                        Function body should span 2 lines or less excluding comments and \
                        whitespace: currently spans 3 lines
                        """
                ),
            ]
        )
    }

    @Test
    func error() {
        let example = Example("""
            func f() {
                let x = 0
                let y = 1
                let z = 2
            }
            """)

        #expect(
            self.violations(example, configuration: ["warning": 1, "error": 2]) == [
                StyleViolation(
                    ruleDescription: FunctionBodyLengthRule.description,
                    severity: .error,
                    location: Location(file: nil, line: 1, character: 1),
                    reason: """
                        Function body should span 2 lines or less excluding comments and \
                        whitespace: currently spans 3 lines
                        """
                ),
            ]
        )
    }

    @Test
    func violationMessages() {
        let types = FunctionBodyLengthRule.description.triggeringExamples.flatMap {
            violations($0, configuration: ["warning": 2])
        }.compactMap {
            $0.reason.split(separator: " ", maxSplits: 1).first
        }

        #expect(
            types == ["Function", "Deinitializer", "Initializer", "Subscript", "Accessor", "Accessor", "Accessor"]
        )
    }

    private func violations(_ example: Example, configuration: Any? = nil) -> [StyleViolation] {
        let config = makeConfig(configuration, FunctionBodyLengthRule.identifier)!
        return TestHelpers.violations(example, config: config)
    }
}
