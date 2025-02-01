import Testing

@testable import SwiftLintBuiltInRules

@Suite
struct LineEndingTests {
    @Test
    func carriageReturnDoesNotCauseError() {
        #expect(
            violations(
                Example(
                    "// swiftlint:disable:next blanket_disable_command\r\n"
                        + "// swiftlint:disable all\r\nprint(123)\r\n"
                )
            ).isEmpty
        )
    }
}
