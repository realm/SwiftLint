import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct OpaqueOverExistentialParameterRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "opaque_over_existential",
        name: "Opaque Over Existential Parameter",
        description: "Prefer opaque over existential type in function parameter",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func f(_: some P) {}"),
            Example("func f(_: (some P)?) {}"),
            Example("func f(_: some P & Q) {}"),
            Example("func f(_: any P.Type) {}"),
            Example("func f(_: (any P.Type)?) {}"),
            Example("func f(_: borrowing any ~Copyable.Type) {}"),
            Example("func f(_: () -> Int = { let i: any P = p(); return i.get() }) {}"),
            Example("func f(_: [any P]) {}"),
            Example("func f(_: [any P: any Q]) {}"),
            Example("func f(_: () -> any P) {}"),
        ],
        triggeringExamples: [
            Example("func f(_: ↓any P) {}"),
            Example("func f(_: (↓any P)?) {}"),
            Example("func f(_: ↓any P & Q) {}"),
            Example("func f(_: borrowing ↓any ~Copyable) {}"),
            Example("func f(_: borrowing (↓any ~Copyable)?) {}"),
            Example("func f(_: (↓any P, ↓any Q)) {}"),
        ],
        corrections: [
            Example("func f(_: any P) {}"):
                Example("func f(_: some P) {}"),
            Example("func f(_: (any P)?) {}"):
                Example("func f(_: (some P)?) {}"),
            Example("func f(_: any P & Q) {}"):
                Example("func f(_: some P & Q) {}"),
            Example("func f(_: /* comment */ any P/* comment*/) {}"):
                Example("func f(_: /* comment */ some P/* comment*/) {}"),
            Example("func f(_: borrowing (any ~Copyable)?) {}"):
                Example("func f(_: borrowing (some ~Copyable)?) {}"),
        ]
    )
}

private extension OpaqueOverExistentialParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionParameterSyntax) {
            AnyTypeVisitor(viewMode: .sourceAccurate).walk(tree: node.type, handler: \.anyRanges).forEach { range in
                violations.append(.init(
                    position: range.start,
                    correction: .init(start: range.start, end: range.end, replacement: "some")
                ))
            }
        }
    }
}

private class AnyTypeVisitor: SyntaxVisitor {
    var anyRanges = [(start: AbsolutePosition, end: AbsolutePosition)]()

    override func visitPost(_ node: SomeOrAnyTypeSyntax) {
        let specifier = node.someOrAnySpecifier
        if specifier.tokenKind == .keyword(.any), !node.constraint.isMetaType {
            anyRanges.append((specifier.positionAfterSkippingLeadingTrivia, specifier.endPositionBeforeTrailingTrivia))
        }
    }

    override func visit(_: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }
}

private extension TypeSyntax {
    var isMetaType: Bool {
        if `is`(MetatypeTypeSyntax.self) {
            return true
        }
        if let suppressedType = `as`(SuppressedTypeSyntax.self) {
            return suppressedType.type.isMetaType
        }
        return false
    }
}
