import SwiftSyntax

// TODO: [09/07/2024] Remove deprecation warning after ~2 years.
private let warnDeprecatedOnceImpl: Void = {
    Issue.ruleDeprecated(ruleID: AnyObjectProtocolRule.description.identifier).print()
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

@SwiftSyntaxRule(deprecated: true)
struct AnyObjectProtocolRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "anyobject_protocol",
        name: "AnyObject Protocol",
        description: "Prefer using `AnyObject` over `class` for class-only protocols",
        kind: .lint,
        nonTriggeringExamples: [
            Example("protocol SomeProtocol {}"),
            Example("protocol SomeClassOnlyProtocol: AnyObject {}"),
            Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}"),
            Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}")
        ],
        triggeringExamples: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}")
        ],
        corrections: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}"):
                Example("protocol SomeClassOnlyProtocol: AnyObject {}"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}"):
                Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}"):
                Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}")
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension AnyObjectProtocolRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClassRestrictionTypeSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
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

        override func visit(_ node: InheritedTypeSyntax) -> InheritedTypeSyntax {
            let typeName = node.type
            guard
                typeName.is(ClassRestrictionTypeSyntax.self),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return super.visit(
                node.with(
                    \.type,
                    TypeSyntax(
                        IdentifierTypeSyntax(name: .identifier("AnyObject"), genericArgumentClause: nil)
                            .with(\.leadingTrivia, typeName.leadingTrivia)
                            .with(\.trailingTrivia, typeName.trailingTrivia)
                    )
                )
            )
        }
    }
}
