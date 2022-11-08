import Foundation
import SwiftSyntax

private let attributeNamesImplyingObjc: Set<String> = [
    "IBAction", "IBOutlet", "IBInspectable", "GKInspectable", "IBDesignable", "NSManaged"
]

struct RedundantObjcAttributeRule: SwiftSyntaxRule, SubstitutionCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "redundant_objc_attribute",
        name: "Redundant @objc Attribute",
        description: "Objective-C attribute (@objc) is redundant in declaration.",
        kind: .idiomatic,
        nonTriggeringExamples: RedundantObjcAttributeRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantObjcAttributeRuleExamples.triggeringExamples,
        corrections: RedundantObjcAttributeRuleExamples.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        final class Visitor: ViolationsSyntaxVisitor {
            override func visitPost(_ node: AttributeListSyntax) {
                if let objcAttribute = node.violatingObjCAttribute {
                    violations.append(objcAttribute.positionAfterSkippingLeadingTrivia)
                }
            }
        }
        return Visitor(viewMode: .sourceAccurate)
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        makeVisitor(file: file)
            .walk(tree: file.syntaxTree, handler: \.violations)
            .compactMap { violation in
                let end = AbsolutePosition(utf8Offset: violation.position.utf8Offset + "@objc".count)
                return file.stringView.NSRange(start: violation.position, end: end)
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
            .first { attribute in
                attribute.attributeName.tokenKind == .contextualKeyword("objc") &&
                    attribute.argument == nil
            }
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

extension RedundantObjcAttributeRule {
    func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        var whitespaceAndNewlineOffset = 0
        let nsCharSet = CharacterSet.whitespacesAndNewlines.bridge()
        let nsContent = file.contents.bridge()
        while nsCharSet
            .characterIsMember(nsContent.character(at: violationRange.upperBound + whitespaceAndNewlineOffset)) {
            whitespaceAndNewlineOffset += 1
        }

        let withTrailingWhitespaceAndNewlineRange = NSRange(location: violationRange.location,
                                                            length: violationRange.length + whitespaceAndNewlineOffset)
        return (withTrailingWhitespaceAndNewlineRange, "")
    }
}
