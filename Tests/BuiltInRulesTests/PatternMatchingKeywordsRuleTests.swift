import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct PatternMatchingKeywordsRuleTests {
    @Test
    func violationReasonForTuples() throws {
        let config = try #require(makeConfig(nil, PatternMatchingKeywordsRule.identifier))
        let example = Example("switch foo { case (let x, let y): break }")
        let violations = violations(example, config: config)

        #expect(violations.count == 2)
        #expect(violations.first?.reason == PatternMatchingKeywordsRule.Reason.tuples)
    }

    @Test
    func violationReasonForEnumAssociatedValues() throws {
        let config = try #require(makeConfig(nil, PatternMatchingKeywordsRule.identifier))
        let example = Example("switch foo { case .bar(let x, let y): break }")
        let violations = violations(example, config: config)

        #expect(violations.count == 2)
        #expect(violations.first?.reason == PatternMatchingKeywordsRule.Reason.enumAssociatedValues)
    }

    @Test
    func regressionExamples() {
        let triggering = #examples([
            "switch foo { case (.yamlParsing(↓let x), .yamlParsing(↓let y)): break }",
            "switch foo { case (.yamlParsing(↓var x), (.yamlParsing(↓var y), _)): break }",
            """
            do {} catch Foo.outer(.inner(↓let x), .inner(↓let y)) {}
            """,
        ])

        let nonTriggering = #examples([
            "switch foo { case (.yamlParsing(var x), (.yamlParsing(var y), z)): break }",
            "switch foo { case (foo, let x): break }",
            "if case (foo, let x) = value {}",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering,
                triggeringExamples: triggering
            )
        )
    }

    @Test
    func labeledAssociatedValues() {
        let triggering = #examples([
            "switch foo { case .foo(bar: ↓let lhs, baz: ↓let rhs): break }",
            "switch foo { case .foo(bar: ↓var lhs, baz: ↓var rhs): break }",
            "do {} catch .foo(bar: ↓let x, baz: ↓let y) {}",
        ])

        let nonTriggering = #examples([
            "switch foo { case let .foo(bar: lhs, baz: rhs): break }",
            "switch foo { case var .foo(bar: lhs, baz: rhs): break }",
            "switch foo { case .foo(bar: existingValue, baz: let x): break }",
            "switch foo { case .foo(bar: let x, baz: existingValue): break }",
            "do {} catch let .foo(bar: x, baz: y) {}",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering,
                triggeringExamples: triggering
            )
        )
    }

    @Test
    func singleBindingDoesNotTrigger() {
        let examples = #examples([
            "switch foo { case (let x, y): break }",
            "switch foo { case .foo(let x, y): break }",
            "switch foo { case (.foo(let x), y): break }",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: examples
            )
        )
    }

    @Test
    func neutralElementsDoNotBlockLift() {
        let examples = #examples([
            "switch foo { case (↓let x, ↓let y, _): break }",
            "switch foo { case (↓let x, ↓let y, 1): break }",
            "switch foo { case (↓let x, ↓let y, .foo): break }",
            "switch foo { case (↓let x, ↓let y, s.t): break }",
            "switch foo { case .foo(↓let x, ↓let y, _): break }",
            "switch foo { case .foo(.bar(↓let x), .bar(↓let y), .baz): break }",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                triggeringExamples: examples
            )
        )
    }

    @Test
    func threeAlternativeMultiPatternCase() {
        let triggering = #examples([
            "switch foo { case .foo(↓let x, ↓let y), .bar(↓let x, ↓let y), .baz(↓let x, ↓let y): break }",
        ])

        let nonTriggering = #examples([
            "switch foo { case let .foo(x, y), let .bar(x, y), let .baz(x, y): break }",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering,
                triggeringExamples: triggering
            )
        )
    }

    @Test
    func forCaseWithEnumAssociatedValues() {
        let triggering = #examples([
            "for case .foo(↓let x, ↓let y) in values {}",
        ])

        let nonTriggering = #examples([
            "for case let .foo(x, y) in values {}",
            "for case .foo(existingValue, let x) in values {}",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering,
                triggeringExamples: triggering
            )
        )
    }

    @Test
    func sanityChecksForNonInterestingPatterns() {
        let examples = #examples([
            "switch foo { case _: break }",
            "switch foo { case .foo: break }",
            "switch foo { case 42: break }",
            "switch foo { case existingValue: break }",
        ])

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: examples
            )
        )
    }
}
