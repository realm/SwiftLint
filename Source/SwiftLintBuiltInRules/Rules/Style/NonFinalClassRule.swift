import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(correctable: true, optIn: true)
struct NonFinalClassRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "non_final_class",
        name: "Non-Final Class",
        description: "Classes should be marked as `final` unless they are explicitly `open`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("final class MyClass {}"),
            Example("open class MyClass {}"),
            Example("public final class MyClass {}"),
        ],
        triggeringExamples: [
            Example("class MyClass {}"),
            Example("public class MyClass {}"),
        ],
        corrections: [
            Example("class MyClass {}"): Example("final class MyClass {}"),
            Example("public class MyClass {}"): Example("public final class MyClass {}"),
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType>? {
        Visitor(configuration: configuration, file: file)
    }

    private final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            let modifiers = node.modifiers
            if !modifiers.contains(where: { $0.name.text == "final" }) && !modifiers.contains(where: { $0.name.text == "open" }) {
                let classToken = node.classKeyword
                violations.append(.init(
                    position: classToken.positionAfterSkippingLeadingTrivia,
                    reason: "Classes should be marked as `final` unless they are explicitly `open`",
                    correction: .init(
                        start: classToken.positionAfterSkippingLeadingTrivia,
                        end: classToken.positionAfterSkippingLeadingTrivia,
                        replacement: "final "
                    )
                ))
            }
            return .visitChildren
        }
    }
}
