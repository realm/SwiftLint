import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct FinalTestCaseRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = FinalTestCaseConfiguration()

    static var description = RuleDescription(
        identifier: "final_test_case",
        name: "Final Test Case",
        description: "Test cases should be final",
        kind: .performance,
        nonTriggeringExamples: [
            Example("final class Test: XCTestCase {}"),
            Example("open class Test: XCTestCase {}"),
            Example("public final class Test: QuickSpec {}"),
            Example("class Test: MyTestCase {}"),
            Example("struct Test: MyTestCase {}", configuration: ["test_parent_classes": "MyTestCase"])
        ],
        triggeringExamples: [
            Example("class ↓Test: XCTestCase {}"),
            Example("public class ↓Test: QuickSpec {}"),
            Example("class ↓Test: MyTestCase {}", configuration: ["test_parent_classes": "MyTestCase"])
        ],
        corrections: [
            Example("class ↓Test: XCTestCase {}"):
                Example("final class Test: XCTestCase {}"),
            Example("internal class ↓Test: XCTestCase {}"):
                Example("internal final class Test: XCTestCase {}")
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
       Rewriter(
           configuration: configuration,
           locationConverter: file.locationConverter,
           disabledRegions: disabledRegions(file: file)
       )
   }
}

private extension FinalTestCaseRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClassDeclSyntax) {
            if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
                violations.append(node.name.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let configuration: FinalTestCaseConfiguration

        init(configuration: FinalTestCaseConfiguration,
             locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange]) {
            self.configuration = configuration
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            var newNode = node
            if node.isNonFinalTestClass(parentClasses: configuration.testParentClasses) {
                correctionPositions.append(node.name.positionAfterSkippingLeadingTrivia)
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
           inheritanceClause.containsInheritedType(inheritedTypes: parentClasses)
        && !modifiers.contains(keyword: .open)
        && !modifiers.contains(keyword: .final)
    }
}
