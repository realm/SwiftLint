import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TodoRuleTests {
    @Test
    func todo() {
        verifyRule(TodoRule.description, commentDoesntViolate: false)
    }

    @Test
    func todoMessage() {
        let example = Example("fatalError() // TODO: Implement")
        let violations = self.violations(example)
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "TODOs should be resolved (Implement)")
    }

    @Test
    func fixMeMessage() {
        let example = Example("fatalError() // FIXME: Implement")
        let violations = self.violations(example)
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "FIXMEs should be resolved (Implement)")
    }

    @Test
    func onlyFixMe() {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
            """)
        let violations = self.violations(example, config: ["only": ["FIXME"]])
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "FIXMEs should be resolved (Implement fixme)")
    }

    @Test
    func onlyTodo() {
        let example = Example("""
            fatalError() // TODO: Implement todo
            fatalError() // FIXME: Implement fixme
            """)
        let violations = self.violations(example, config: ["only": ["TODO"]])
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "TODOs should be resolved (Implement todo)")
    }

    private func violations(_ example: Example, config: Any? = nil) -> [StyleViolation] {
        let config = makeConfig(config, TodoRule.identifier)!
        return TestHelpers.violations(example, config: config)
    }
}
