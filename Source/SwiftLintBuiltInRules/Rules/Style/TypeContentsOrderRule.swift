import SourceKittenFramework
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct TypeContentsOrderRule: Rule {
    private typealias TypeContentOffset = (typeContent: TypeContent, offset: ByteCount)

    var configuration = TypeContentsOrderConfiguration()

    static let description = RuleDescription(
        identifier: "type_contents_order",
        name: "Type Contents Order",
        description: "Specifies the order of subtypes, properties, methods & more within a type.",
        kind: .style,
        nonTriggeringExamples: TypeContentsOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: TypeContentsOrderRuleExamples.triggeringExamples
    )
}

private extension TypeContentsOrderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private static let viewLifecycleMethodNames = [
            "loadView",
            "loadViewIfNeeded",
            "viewIsAppearing",
            "viewDidLoad",
            "viewWillAppear",
            "viewWillLayoutSubviews",
            "viewDidLayoutSubviews",
            "viewDidAppear",
            "viewWillDisappear",
            "viewDidDisappear",
            "willMove",
        ]

        override func visitPost(_ node: ActorDeclSyntax) {
            collectViolations(for: node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolations(for: node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolations(for: node)
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            collectViolations(for: node)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolations(for: node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolations(for: node)
        }

        private func collectViolations(for typeDecl: some DeclGroupSyntax) {
            let categories = typeDecl.memberBlock.members.compactMap(categorize)
            let sortedCategories = categories.sorted { $0.position < $1.position }

            var lastMatchingIndex = -1
            for expectedTypesContents in configuration.order {
                var potentialViolatingIndexes = [Int]()

                let startIndex = lastMatchingIndex + 1
                for index in startIndex..<sortedCategories.count {
                    let category = sortedCategories[index].category
                    if expectedTypesContents.contains(category) {
                        lastMatchingIndex = index
                    } else {
                        potentialViolatingIndexes.append(index)
                    }
                }

                let violatingIndexes = potentialViolatingIndexes.filter { $0 < lastMatchingIndex }
                violatingIndexes.forEach { index in
                    let category = sortedCategories[index].category
                    let content = category.rawValue
                    let expected = expectedTypesContents.map(\.rawValue).joined(separator: ",")
                    let article = ["a", "e", "i", "o", "u"].contains(content.substring(from: 0, length: 1)) ? "An" : "A"
                    violations.append(.init(
                        position: sortedCategories[index].position,
                        reason: "\(article) '\(content)' should not be placed amongst the type content(s) '\(expected)'"
                    ))
                }
            }
        }

        // swiftlint:disable:next cyclomatic_complexity
        private func categorize(member: MemberBlockItemSyntax) -> (position: AbsolutePosition, category: TypeContent)? {
            let decl = member.decl
            if let decl = decl.as(EnumCaseDeclSyntax.self) {
                return (decl.caseKeyword.positionAfterSkippingLeadingTrivia, .case)
            }
            if let decl = decl.as(TypeAliasDeclSyntax.self) {
                return (decl.typealiasKeyword.positionAfterSkippingLeadingTrivia, .typeAlias)
            }
            if let decl = decl.as(AssociatedTypeDeclSyntax.self) {
                return (decl.associatedtypeKeyword.positionAfterSkippingLeadingTrivia, .associatedType)
            }
            if let decl = decl.asProtocol((any DeclGroupSyntax).self) {
                return (decl.introducer.positionAfterSkippingLeadingTrivia, .subtype)
            }
            if let decl = decl.as(VariableDeclSyntax.self) {
                let position = decl.modifiers.first(where: \.isStaticOrClass)?.positionAfterSkippingLeadingTrivia
                    ?? decl.bindingSpecifier.positionAfterSkippingLeadingTrivia
                if decl.modifiers.containsStaticOrClass {
                    return (position, .typeProperty)
                }
                if decl.attributes.contains(attributeNamed: "IBOutlet") {
                    return (position, .ibOutlet)
                }
                if decl.attributes.contains(attributeNamed: "IBInspectable") {
                    return (position, .ibInspectable)
                }
                return (position, .instanceProperty)
            }
            if let decl = decl.as(FunctionDeclSyntax.self) {
                let position = decl.modifiers.first(where: \.isStaticOrClass)?.positionAfterSkippingLeadingTrivia
                    ?? decl.funcKeyword.positionAfterSkippingLeadingTrivia
                if decl.modifiers.containsStaticOrClass {
                    return (position, .typeMethod)
                }
                if Self.viewLifecycleMethodNames.contains(decl.name.text) {
                    return (position, .viewLifeCycleMethod)
                }
                if decl.attributes.contains(attributeNamed: "IBAction") {
                    return (position, .ibAction)
                }
                if decl.attributes.contains(attributeNamed: "IBSegueAction") {
                    return (position, .ibSegueAction)
                }
                return (position, .otherMethod)
            }
            if let decl = decl.as(InitializerDeclSyntax.self) {
                return (decl.initKeyword.positionAfterSkippingLeadingTrivia, .initializer)
            }
            if let decl = decl.as(DeinitializerDeclSyntax.self) {
                return (decl.deinitKeyword.positionAfterSkippingLeadingTrivia, .deinitializer)
            }
            if let decl = decl.as(SubscriptDeclSyntax.self) {
                return (decl.subscriptKeyword.positionAfterSkippingLeadingTrivia, .subscript)
            }
            return nil
        }
    }
}
