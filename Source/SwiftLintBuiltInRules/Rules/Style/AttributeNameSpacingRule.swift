import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct AttributeNameSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "attribute_name_spacing",
        name: "Attribute Name Spacing",
        description: """
            This rule prevents trailing spaces after attribute names, ensuring compatibility \
            with Swift 6 where a space between an attribute name and the opening parenthesis \
            results in a compilation error (e.g. `@MyPropertyWrapper ()`, `private (set)`).
            """,
        kind: .style,
        nonTriggeringExamples: #examples([
            "private(set) var foo: Bool = false",
            "fileprivate(set) var foo: Bool = false",
            "@MainActor class Foo {}",
            "func funcWithEscapingClosure(_ x: @escaping () -> Int) {}",
            "@available(*, deprecated)",
            "@MyPropertyWrapper(param: 2) ",
            "nonisolated(unsafe) var _value: X?",
            "@testable import SwiftLintCore",
            "func func_type_attribute_with_space(x: @convention(c) () -> Int) {}",
            """
            @propertyWrapper
            struct MyPropertyWrapper {
                var wrappedValue: Int = 1

                init(param: Int) {}
            }
            """,
            """
            let closure2 = { @MainActor
              (a: Int, b: Int) in
            }
            """,
            """
            let closure1 = { @MainActor (a, b) in
            }
            """,
        ]),
        triggeringExamples: #examples([
            "private ↓(set) var foo: Bool = false",
            "fileprivate ↓(set) var foo: Bool = false",
            "public ↓(set) var foo: Bool = false",
            "  public  ↓(set) var foo: Bool = false",
            "@ ↓MainActor class Foo {}",
            "func funcWithEscapingClosure(_ x: @ ↓escaping () -> Int) {}",
            "func funcWithEscapingClosure(_ x: @escaping↓() -> Int) {}",
            "@available ↓(*, deprecated)",
            "@MyPropertyWrapper ↓(param: 2) let a = 1",
            "nonisolated ↓(unsafe) var _value: X?",
            "@MyProperty ↓() class Foo {}",
        ]),
        corrections: #corrections([
            "private↓ (set) var foo: Bool = false": "private(set) var foo: Bool = false",
            "fileprivate↓ (set) var foo: Bool = false": "fileprivate(set) var foo: Bool = false",
            "internal↓ (set) var foo: Bool = false": "internal(set) var foo: Bool = false",
            "public↓ (set) var foo: Bool = false": "public(set) var foo: Bool = false",
            "public↓  (set) var foo: Bool = false": "public(set) var foo: Bool = false",
            "@↓ MainActor": "@MainActor",
            "func test(_ x: @↓ escaping () -> Int) {}": "func test(_ x: @escaping () -> Int) {}",
            "func test(_ x: @escaping↓() -> Int) {}": "func test(_ x: @escaping () -> Int) {}",
            "@available↓ (*, deprecated)": "@available(*, deprecated)",
            "@MyPropertyWrapper↓ (param: 2) let a = 1": "@MyPropertyWrapper(param: 2) let a = 1",
            "nonisolated↓ (unsafe) var _value: X?": "nonisolated(unsafe) var _value: X?",
            "@MyProperty↓ () let a = 1": "@MyProperty() let a = 1",
        ])
    )
}

private extension AttributeNameSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            guard node.detail != nil, node.name.trailingTrivia.isNotEmpty else {
                return
            }

            addViolation(
                startPosition: node.name.endPositionBeforeTrailingTrivia,
                endPosition: node.name.endPosition,
                replacement: "",
                reason: "There must not be any space between access control modifier and scope"
            )
        }

        override func visitPost(_ node: AttributeSyntax) {
            // Check for trailing trivia after the '@' sign. Handles cases like `@ MainActor` / `@ escaping`.
            if node.atSign.trailingTrivia.isNotEmpty {
                addViolation(
                    startPosition: node.atSign.endPositionBeforeTrailingTrivia,
                    endPosition: node.atSign.endPosition,
                    replacement: "",
                    reason: "Attributes must not have trivia between `@` and the identifier"
                )
            }

            let hasTrailingTrivia = node.attributeName.trailingTrivia.isNotEmpty

            // Handles cases like `@MyPropertyWrapper (param: 2)`.
            if node.arguments != nil, hasTrailingTrivia {
                addViolation(
                    startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
                    endPosition: node.attributeName.endPosition,
                    replacement: "",
                    reason: "Attribute declarations with arguments must not have trailing trivia"
                )
            }

            if !hasTrailingTrivia, node.isEscaping {
                // Handles cases where escaping has the wrong spacing: `@escaping()`
                addViolation(
                    startPosition: node.attributeName.endPositionBeforeTrailingTrivia,
                    endPosition: node.attributeName.endPosition,
                    replacement: " ",
                    reason: "`@escaping` must have a trailing space before the associated type"
                )
            }
        }

        private func addViolation(
            startPosition: AbsolutePosition,
            endPosition: AbsolutePosition,
            replacement: String,
            reason: String
        ) {
            let correction = ReasonedRuleViolation.ViolationCorrection(
                start: startPosition,
                end: endPosition,
                replacement: replacement
            )

            let violation = ReasonedRuleViolation(
                position: endPosition,
                reason: reason,
                severity: configuration.severity,
                correction: correction
            )
            violations.append(violation)
        }
    }
}

private extension AttributeSyntax {
    var isEscaping: Bool {
        attributeNameText == "escaping"
    }
}
