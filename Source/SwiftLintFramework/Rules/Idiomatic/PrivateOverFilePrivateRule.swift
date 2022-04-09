import SwiftSyntax

struct PrivateOverFilePrivateRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = PrivateOverFilePrivateRuleConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "private_over_fileprivate",
        name: "Private over Fileprivate",
        description: "Prefer `private` over `fileprivate` declarations.",
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(validateExtensions: configuration.validateExtensions)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            validateExtensions: configuration.validateExtensions,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension PrivateOverFilePrivateRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let validateExtensions: Bool

        init(validateExtensions: Bool) {
            self.validateExtensions = validateExtensions
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if validateExtensions, let privateModifier = node.modifiers.fileprivateModifier {
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

        override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
            if let privateModifier = node.modifiers.fileprivateModifier {
                violations.append(privateModifier.positionAfterSkippingLeadingTrivia)
            }
            return .skipChildren
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        private let validateExtensions: Bool
        private let locationConverter: SourceLocationConverter
        private let disabledRegions: [SourceRange]

        init(validateExtensions: Bool, locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.validateExtensions = validateExtensions
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        // don't call super in any of the `visit` methods to avoid digging into the children
        override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            guard validateExtensions, let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }

        override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
            guard let modifier = node.modifiers.fileprivateModifier,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return DeclSyntax(node)
            }

            correctionPositions.append(modifier.positionAfterSkippingLeadingTrivia)
            let newNode = node.withModifiers(node.modifiers?.replacing(fileprivateModifier: modifier))
            return DeclSyntax(newNode)
        }
    }
}

private extension ModifierListSyntax? {
    var fileprivateModifier: DeclModifierSyntax? {
        self?.first { $0.name.tokenKind == .fileprivateKeyword }
    }
}

private extension ModifierListSyntax {
    func replacing(fileprivateModifier: DeclModifierSyntax) -> ModifierListSyntax? {
        replacing(
            childAt: fileprivateModifier.indexInParent,
            with: fileprivateModifier.withName(
                .privateKeyword(
                    leadingTrivia: fileprivateModifier.leadingTrivia ?? .zero,
                    trailingTrivia: fileprivateModifier.trailingTrivia ?? .zero
                )
            )
        )
    }
}
