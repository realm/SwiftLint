import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct IdentifierNameRuleTests {
    @Test
    func identifierNameWithExcluded() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "let Apple = 0",
            "let some_apple = 0",
            "let Test123 = 0",
        ])
        let triggeringExamples = baseDescription.triggeringExamples + #examples([
            "let ap_ple = 0",
            "let AppleJuice = 0",
        ])
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
    }

    @Test
    func identifierNameWithAllowedSymbols() {
        let baseDescription = IdentifierNameRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + #examples([
            "let myLet$ = 0",
            "let myLet% = 0",
            "let myLet$% = 0",
            "let _myLet = 0",
        ])
        let triggeringExamples = baseDescription.triggeringExamples.filter { !$0.code.contains("_") }
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%", "_"]])
    }

    @Test
    func identifierNameWithAllowedSymbolsAndViolation() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = #examples([
            "let ↓my_Let$ = 0"
        ])

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func identifierNameWithIgnoreStartWithLowercase() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamplesToRemove = #examples([
            "let ↓MyLet = 0",
            "enum Foo { case ↓MyEnum }",
            "func ↓IsOperator(name: String) -> Bool",
            "class C { class let ↓MyLet = 0 }",
            "class C { static func ↓MyFunc() {} }",
            "class C { class func ↓MyFunc() {} }",
            "func ↓√ (arg: Double) -> Double { arg }",
        ])
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.removingViolationMarkers()
        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
    }

    @Test
    func startsWithLowercaseCheck() {
        let triggeringExamples = #examples([
            "let ↓MyLet = 0",
            "enum Foo { case ↓MyCase }",
            "func ↓IsOperator(name: String) -> Bool { true }",
        ])
        let nonTriggeringExamples = #examples([
            "let myLet = 0",
            "enum Foo { case myCase }",
            "func isOperator(name: String) -> Bool { true }",
        ])

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: triggeringExamples)
                .with(nonTriggeringExamples: nonTriggeringExamples),
            ruleConfiguration: ["validates_start_with_lowercase": "error"]
        )

        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: [])
                .with(nonTriggeringExamples: nonTriggeringExamples + triggeringExamples.removingViolationMarkers()),
            ruleConfiguration: ["validates_start_with_lowercase": "off"]
        )
    }

    @Test
    func startsWithLowercaseCheckInCombinationWithAllowedSymbols() {
        verifyRule(
            IdentifierNameRule.description
                .with(triggeringExamples: #examples([
                    "let ↓OneLet = 0"
                ]))
                .with(nonTriggeringExamples: #examples([
                    "let MyLet = 0",
                    "enum Foo { case myCase }",
                ])),
            ruleConfiguration: [
                "validates_start_with_lowercase": "error",
                "allowed_symbols": ["M"],
            ] as [String: any Sendable]
        )
    }

    @Test
    func linuxCrashOnEmojiNames() {
        let baseDescription = IdentifierNameRule.description
        let triggeringExamples = #examples([
            "let 👦🏼 = \"👦🏼\""
        ])

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
    }

    @Test
    func functionNameInViolationMessage() {
        let example = SwiftLintFile(contents: "func _abc(arg: String) {}")
        let violations = IdentifierNameRule().validate(file: example)
        #expect(
            violations.map(\.reason)
                == ["Function name \'_abc(arg:)\' should start with a lowercase character"]
        )
    }
}
