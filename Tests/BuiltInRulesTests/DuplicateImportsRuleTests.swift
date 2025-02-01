import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct DuplicateImportsRuleTests {
    @Test
    func disableCommand() {
        let content = """
            import InspireAPI
            // swiftlint:disable:next duplicate_imports
            import class InspireAPI.Response
            """
        let file = SwiftLintFile(contents: content)

        _ = DuplicateImportsRule().correct(file: file)

        #expect(file.contents == content)
    }
}
