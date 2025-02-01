import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ChildOptionSeverityConfigurationTests {
    typealias TesteeType = ChildOptionSeverityConfiguration<RuleMock>

    @Test
    func severity() {
        #expect(TesteeType.off.severity == nil)
        #expect(TesteeType.warning.severity == .warning)
        #expect(TesteeType.error.severity == .error)
    }

    @Test
    func fromConfig() throws {
        var testee = TesteeType.off

        try testee.apply(configuration: "warning")
        #expect(testee == .warning)

        try testee.apply(configuration: "error")
        #expect(testee == .error)

        try testee.apply(configuration: "off")
        #expect(testee == .off)
    }

    @Test
    func invalidConfig() {
        var testee = TesteeType.off

        #expect(throws: (any Error).self) {
            try testee.apply(configuration: "no")
        }
        #expect(throws: (any Error).self) {
            try testee.apply(configuration: 1)
        }
    }
}
