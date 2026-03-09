@testable import SwiftLintBuiltInRules
import TestHelpers

final class PatternMatchingKeywordsRuleTests: SwiftLintTestCase {
    func testRegressionExamples() {
        let triggering = [
            "switch foo { case (.yamlParsing(↓let x), .yamlParsing(↓let y)): break }",
            "switch foo { case (.yamlParsing(↓var x), (.yamlParsing(↓var y), _)): break }",
            """
            do {} catch Foo.outer(.inner(↓let x), .inner(↓let y)) {}
            """,
        ]

        let nonTriggering = [
            "switch foo { case (.yamlParsing(var x), (.yamlParsing(var y), z)): break }",
            "switch foo { case (foo, let x): break }",
            "if case (foo, let x) = value {}",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering.map { Example($0) },
                triggeringExamples: triggering.map { Example($0) }
            )
        )
    }

    func testLabeledAssociatedValues() {
        let triggering = [
            "switch foo { case .foo(bar: ↓let lhs, baz: ↓let rhs): break }",
            "switch foo { case .foo(bar: ↓var lhs, baz: ↓var rhs): break }",
            "do {} catch .foo(bar: ↓let x, baz: ↓let y) {}",
        ]

        let nonTriggering = [
            "switch foo { case let .foo(bar: lhs, baz: rhs): break }",
            "switch foo { case var .foo(bar: lhs, baz: rhs): break }",
            "switch foo { case .foo(bar: existingValue, baz: let x): break }",
            "switch foo { case .foo(bar: let x, baz: existingValue): break }",
            "do {} catch let .foo(bar: x, baz: y) {}",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering.map { Example($0) },
                triggeringExamples: triggering.map { Example($0) }
            )
        )
    }

    func testSingleBindingDoesNotTrigger() {
        let examples = [
            "switch foo { case (let x, y): break }",
            "switch foo { case .foo(let x, y): break }",
            "switch foo { case (.foo(let x), y): break }",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: examples.map { Example($0) }
            )
        )
    }

    func testNeutralElementsDoNotBlockLift() {
        let examples = [
            "switch foo { case (↓let x, ↓let y, _): break }",
            "switch foo { case (↓let x, ↓let y, 1): break }",
            "switch foo { case (↓let x, ↓let y, .foo): break }",
            "switch foo { case (↓let x, ↓let y, s.t): break }",
            "switch foo { case .foo(↓let x, ↓let y, _): break }",
            "switch foo { case .foo(.bar(↓let x), .bar(↓let y), .baz): break }",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                triggeringExamples: examples.map { Example($0) }
            )
        )
    }

    func testThreeAlternativeMultiPatternCase() {
        let triggering = [
            "switch foo { case .foo(↓let x, ↓let y), .bar(↓let x, ↓let y), .baz(↓let x, ↓let y): break }",
        ]

        let nonTriggering = [
            "switch foo { case let .foo(x, y), let .bar(x, y), let .baz(x, y): break }",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering.map { Example($0) },
                triggeringExamples: triggering.map { Example($0) }
            )
        )
    }

    func testForCaseWithEnumAssociatedValues() {
        let triggering = [
            "for case .foo(↓let x, ↓let y) in values {}",
        ]

        let nonTriggering = [
            "for case let .foo(x, y) in values {}",
            "for case .foo(existingValue, let x) in values {}",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: nonTriggering.map { Example($0) },
                triggeringExamples: triggering.map { Example($0) }
            )
        )
    }

    func testSanityChecksForNonInterestingPatterns() {
        let examples = [
            "switch foo { case _: break }",
            "switch foo { case .foo: break }",
            "switch foo { case 42: break }",
            "switch foo { case existingValue: break }",
        ]

        verifyRule(
            PatternMatchingKeywordsRule.description.with(
                nonTriggeringExamples: examples.map { Example($0) }
            )
        )
    }
}
