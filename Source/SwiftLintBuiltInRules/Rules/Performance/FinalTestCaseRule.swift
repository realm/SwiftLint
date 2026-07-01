import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct FinalTestCaseRule: Rule {
    var configuration = FinalTestCaseConfiguration()

    static let description = RuleDescription(
        identifier: "final_test_case",
        name: "Final Test Case",
        description: "Test cases should be final",
        kind: .performance,
        nonTriggeringExamples: #examples([
            "final class Test: XCTestCase {}",
            "open class Test: XCTestCase {}",
            "public final class Test: QuickSpec {}",
            "class Test: MyTestCase {}",
            "struct Test: MyTestCase {}".configuration(["test_parent_classes": "MyTestCase"]),
        ]),
        triggeringExamples: #examples([
            "class ↓Test: XCTestCase {}",
            "public class ↓Test: QuickSpec {}",
            "class ↓Test: MyTestCase {}".configuration(["test_parent_classes": "MyTestCase"]),
        ]),
        corrections: #corrections([
            "class ↓Test: XCTestCase {}":
                "final class Test: XCTestCase {}",
            "internal class ↓Test: XCTestCase {}":
                "internal final class Test: XCTestCase {}",
        ])
    )
}

private extension FinalTestCaseRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClassDeclSyntax) {
            if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
                violations.append(node.name.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            var newNode = node
            if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
                numberOfCorrections += 1
                let finalModifier = DeclModifierSyntax(name: .keyword(.final))
                newNode =
                    if node.modifiers.isEmpty {
                        node
                            .with(\.modifiers, [finalModifier.with(\.leadingTrivia, node.classKeyword.leadingTrivia)])
                            .with(\.classKeyword.leadingTrivia, .space)
                    } else {
                        node
                            .with(\.modifiers, node.modifiers + [finalModifier.with(\.trailingTrivia, .space)])
                    }
            }
            return super.visit(newNode)
        }
    }
}

private extension ClassDeclSyntax {
    func isNonFinalTestClass(parentClasses: Set<String>) -> Bool {
           inheritanceClause.contains(inheritedTypes: parentClasses)
        && !modifiers.contains(keyword: .open)
        && !modifiers.contains(keyword: .final)
    }
}
