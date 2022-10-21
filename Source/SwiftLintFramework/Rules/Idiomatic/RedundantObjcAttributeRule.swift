import SwiftSyntax

private let attributeNamesImplyingObjc: Set<String> = [
    "IBAction", "IBOutlet", "IBInspectable", "GKInspectable", "IBDesignable", "NSManaged"
]

public struct RedundantObjcAttributeRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_objc_attribute",
        name: "Redundant @objc Attribute",
        description: "Objective-C attribute (@objc) is redundant in declaration.",
        kind: .idiomatic,
        nonTriggeringExamples: RedundantObjcAttributeRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantObjcAttributeRuleExamples.triggeringExamples,
        corrections: RedundantObjcAttributeRuleExamples.corrections
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension RedundantObjcAttributeRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: AttributeListSyntax) {
            if let objcAttribute = node.violatingObjCAttribute {
                violations.append(objcAttribute.positionAfterSkippingLeadingTrivia)
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

        override func visit(_ node: AttributeListSyntax) -> Syntax {
            guard
                let objcAttribute = node.violatingObjCAttribute,
                let index = node.firstIndex(of: Syntax(objcAttribute)),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(objcAttribute.positionAfterSkippingLeadingTrivia)

            // There's an opportunity to improve how we clean up whitespace here.
            let emptyObjCAttribute = objcAttribute
                .withAttributeName(.contextualKeyword("", leadingTrivia: objcAttribute.atSignToken.leadingTrivia))
                .withAtSignToken(nil)
            let newNode = node.replacing(childAt: node.distance(from: node.startIndex, to: index),
                                         with: Syntax(emptyObjCAttribute))
            return super.visit(newNode)
        }
    }
}

private extension AttributeListSyntax {
    var hasObjCMembers: Bool {
        contains { $0.as(AttributeSyntax.self)?.attributeName.tokenKind == .identifier("objcMembers") }
    }

    var objCAttribute: AttributeSyntax? {
        lazy
            .compactMap { $0.as(AttributeSyntax.self) }
            .first { $0.attributeName.tokenKind == .contextualKeyword("objc") }
    }

    var hasAttributeImplyingObjC: Bool {
        contains { element in
            guard case let .identifier(attributeName) = element.as(AttributeSyntax.self)?.attributeName.tokenKind else {
                return false
            }

            return attributeNamesImplyingObjc.contains(attributeName)
        }
    }
}

private extension Syntax {
    var isFunctionOrStoredProperty: Bool {
        if self.is(FunctionDeclSyntax.self) {
            return true
        } else if let variableDecl = self.as(VariableDeclSyntax.self),
                  variableDecl.bindings.allSatisfy({ $0.accessor == nil }) {
            return true
        } else {
            return false
        }
    }
}

private extension AttributeListSyntax {
    var violatingObjCAttribute: AttributeSyntax? {
        guard let objcAttribute = objCAttribute else {
            return nil
        }

        if hasAttributeImplyingObjC, parent?.is(ExtensionDeclSyntax.self) != true {
            return objcAttribute
        } else if parent?.isFunctionOrStoredProperty == true,
                  let parentClassDecl = parent?.parent?.parent?.parent?.parent?.as(ClassDeclSyntax.self),
                  parentClassDecl.attributes?.hasObjCMembers == true {
            return objcAttribute
        } else if let parentExtensionDecl = parent?.parent?.parent?.parent?.parent?.as(ExtensionDeclSyntax.self),
                  parentExtensionDecl.attributes?.objCAttribute != nil {
            return objcAttribute
        } else {
            return nil
        }
    }
}
