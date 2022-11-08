import SwiftSyntax
import SwiftSyntaxBuilder

struct ToggleBoolRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "toggle_bool",
        name: "Toggle Bool",
        description: "Prefer `someBool.toggle()` over `someBool = !someBool`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("isHidden.toggle()\n"),
            Example("view.clipsToBounds.toggle()\n"),
            Example("func foo() { abc.toggle() }"),
            Example("view.clipsToBounds = !clipsToBounds\n"),
            Example("disconnected = !connected\n"),
            Example("result = !result.toggle()")
        ],
        triggeringExamples: [
            Example("↓isHidden = !isHidden\n"),
            Example("↓view.clipsToBounds = !view.clipsToBounds\n"),
            Example("func foo() { ↓abc = !abc }")
        ],
        corrections: [
            Example("↓isHidden = !isHidden\n"): Example("isHidden.toggle()\n"),
            Example("↓view.clipsToBounds = !view.clipsToBounds\n"): Example("view.clipsToBounds.toggle()\n"),
            Example("func foo() { ↓abc = !abc }"): Example("func foo() { abc.toggle() }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ToggleBoolRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ExprListSyntax) {
            if node.hasToggleBoolViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard
                node.hasToggleBoolViolation,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let newNode = node
                .replacing(childAt: 0, with: "\(node.first!.withoutTrivia()).toggle()")
                .removingLast()
                .removingLast()
                .withLeadingTrivia(node.leadingTrivia ?? .zero)
                .withTrailingTrivia(node.trailingTrivia ?? .zero)

            return super.visit(newNode)
        }
    }
}

private extension ExprListSyntax {
    var hasToggleBoolViolation: Bool {
        guard
            count == 3,
            dropFirst().first?.is(AssignmentExprSyntax.self) == true,
            last?.is(PrefixOperatorExprSyntax.self) == true,
            let lhs = first?.withoutTrivia().description,
            let rhs = last?.withoutTrivia().description,
            rhs == "!\(lhs)"
        else {
            return false
        }

        return true
    }
}
