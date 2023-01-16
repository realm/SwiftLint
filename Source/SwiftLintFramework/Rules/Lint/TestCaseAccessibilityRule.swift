import Foundation
import SwiftSyntax

struct TestCaseAccessibilityRule: SwiftSyntaxRule, OptInRule,
                                         ConfigurationProviderRule, SubstitutionCorrectableRule {
    var configuration = TestCaseAccessibilityConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "test_case_accessibility",
        name: "Test Case Accessibility",
        description: "Test cases should only contain private non-test members",
        kind: .lint,
        nonTriggeringExamples: TestCaseAccessibilityRuleExamples.nonTriggeringExamples,
        triggeringExamples: TestCaseAccessibilityRuleExamples.triggeringExamples,
        corrections: TestCaseAccessibilityRuleExamples.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(allowedPrefixes: configuration.allowedPrefixes, testParentClasses: configuration.testParentClasses)
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        makeVisitor(file: file)
            .walk(tree: file.syntaxTree, handler: \.violations)
            .compactMap {
                file.stringView.NSRange(start: $0.position, end: $0.position)
            }
    }

    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, "private ")
    }
}

private extension TestCaseAccessibilityRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allowedPrefixes: Set<String>
        private let testParentClasses: Set<String>

        init(allowedPrefixes: Set<String>, testParentClasses: Set<String>) {
            self.allowedPrefixes = allowedPrefixes
            self.testParentClasses = testParentClasses
            super.init(viewMode: .sourceAccurate)
        }

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard !testParentClasses.isDisjoint(with: node.inheritedTypes) else {
                return
            }

            violations.append(
                contentsOf: XCTestClassVisitor(allowedPrefixes: allowedPrefixes)
                    .walk(tree: node.members, handler: \.violations)
            )
        }
    }

    final class XCTestClassVisitor: ViolationsSyntaxVisitor {
        private let allowedPrefixes: Set<String>

        init(allowedPrefixes: Set<String>) {
            self.allowedPrefixes = allowedPrefixes
            super.init(viewMode: .sourceAccurate)
        }

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard !node.modifiers.isPrivateOrFileprivate,
                  !XCTestHelpers.isXCTestVariable(node) else {
                return
            }

            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      case let name = pattern.identifier.text,
                      !allowedPrefixes.contains(where: name.hasPrefix) else {
                    continue
                }

                violations.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
                return
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard hasViolation(modifiers: node.modifiers, identifierToken: node.identifier),
                  !XCTestHelpers.isXCTestFunction(node) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if hasViolation(modifiers: node.modifiers, identifierToken: node.identifier) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if hasViolation(modifiers: node.modifiers, identifierToken: node.identifier) {
                violations.append(node.enumKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if hasViolation(modifiers: node.modifiers, identifierToken: node.identifier) {
                violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if hasViolation(modifiers: node.modifiers, identifierToken: node.identifier) {
                violations.append(node.actorKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: TypealiasDeclSyntax) {
            if hasViolation(modifiers: node.modifiers, identifierToken: node.identifier) {
                violations.append(node.typealiasKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func hasViolation(modifiers: ModifierListSyntax?, identifierToken: TokenSyntax) -> Bool {
            guard !modifiers.isPrivateOrFileprivate else {
                return false
            }

            return !allowedPrefixes.contains(where: identifierToken.text.hasPrefix)
        }
    }
}

private extension ClassDeclSyntax {
    var inheritedTypes: [String] {
        inheritanceClause?.inheritedTypeCollection.compactMap { type in
            type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text
        } ?? []
    }
}

private enum XCTestHelpers {
    private static let testVariableNames: Set = [
        "allTests"
    ]

    static func isXCTestFunction(_ function: FunctionDeclSyntax) -> Bool {
        guard !function.modifiers.containsOverride else {
            return true
        }

        return !function.modifiers.containsStaticOrClass &&
            function.identifier.text.hasPrefix("test") &&
            function.signature.input.parameterList.isEmpty
    }

    static func isXCTestVariable(_ variable: VariableDeclSyntax) -> Bool {
        guard !variable.modifiers.containsOverride else {
            return true
        }

        return
            variable.modifiers.containsStaticOrClass &&
            variable.bindings
                .compactMap { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
                .allSatisfy(testVariableNames.contains)
    }
}
