import SwiftSyntax

@SwiftSyntaxRule
struct PrivateOverFilePrivateRule: SwiftSyntaxCorrectableRule {
    var configuration = PrivateOverFilePrivateConfiguration()

    static let description = RuleDescription(
        identifier: "private_over_fileprivate",
        name: "Private over Fileprivate",
        description: "Prefer `private` over `fileprivate` declarations",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("public \n enum MyEnum {}"),
            Example("open extension \n String {}"),
            Example("internal extension String {}"),
            Example("""
            extension String {
              fileprivate func Something(){}
            }
            """),
            Example("""
            class MyClass {
              fileprivate let myInt = 4
            }
            """),
            Example("""
            class MyClass {
              fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            struct Outter {
              struct Inter {
                fileprivate struct Inner {}
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓fileprivate enum MyEnum {}"),
            Example("""
            ↓fileprivate class MyClass {
              fileprivate(set) var myInt = 4
            }
            """)
        ],
        corrections: [
            Example("↓fileprivate enum MyEnum {}"): Example("private enum MyEnum {}"),
            Example("↓fileprivate enum MyEnum { fileprivate class A {} }"):
                Example("private enum MyEnum { fileprivate class A {} }"),
            Example("↓fileprivate class MyClass {\nfileprivate(set) var myInt = 4\n}"):
                Example("private class MyClass {\nfileprivate(set) var myInt = 4\n}")
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            validateExtensions: configuration.validateExtensions,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension PrivateOverFilePrivateRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if configuration.validateExtensions, let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let validateExtensions: Bool

        init(validateExtensions: Bool, locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.validateExtensions = validateExtensions
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        // don't call super in any of the `visit` methods to avoid digging into the children
        override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            guard validateExtensions, let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  let modifierIndex = node.modifiers.fileprivateModifierIndex else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.with(\.modifiers, node.modifiers.replacing(fileprivateModifierIndex: modifierIndex))
            return DeclSyntax(newNode)
        }
    }
}

private extension DeclModifierListSyntax {
    var fileprivateModifierIndex: DeclModifierListSyntax.Index? {
        firstIndex(where: { $0.name.tokenKind == .keyword(.fileprivate) })
    }

    var fileprivateModifier: DeclModifierSyntax? {
        fileprivateModifierIndex.flatMap { self[$0] }
    }

    func replacing(fileprivateModifierIndex: DeclModifierListSyntax.Index) -> DeclModifierListSyntax {
        let fileprivateModifier = self[fileprivateModifierIndex]
        return with(
            \.[fileprivateModifierIndex],
            fileprivateModifier.with(
                \.name,
                .keyword(
                    .private,
                    leadingTrivia: fileprivateModifier.leadingTrivia,
                    trailingTrivia: fileprivateModifier.trailingTrivia
                )
            )
        )
    }
}
