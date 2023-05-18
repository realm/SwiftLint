import SwiftSyntax

// TODO: [09/07/2024] Remove deprecation warning after ~2 years.
private let warnDeprecatedOnceImpl: Void = {
    Issue.ruleDeprecated(ruleID: AnyObjectProtocolRule.description.identifier).print()
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

struct AnyObjectProtocolRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "anyobject_protocol",
        name: "AnyObject Protocol",
        description: "Prefer using `AnyObject` over `class` for class-only protocols",
        kind: .lint,
        nonTriggeringExamples: [
            Example("protocol SomeProtocol {}\n"),
            Example("protocol SomeClassOnlyProtocol: AnyObject {}\n"),
            Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n")
        ],
        triggeringExamples: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}\n"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n")
        ],
        corrections: [
            Example("protocol SomeClassOnlyProtocol: ↓class {}\n"):
                Example("protocol SomeClassOnlyProtocol: AnyObject {}\n"),
            Example("protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"):
                Example("protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n"),
            Example("@objc protocol SomeClassOnlyProtocol: ↓class, SomeInheritedProtocol {}\n"):
                Example("@objc protocol SomeClassOnlyProtocol: AnyObject, SomeInheritedProtocol {}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        warnDeprecatedOnce()
        return Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension AnyObjectProtocolRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClassRestrictionTypeSyntax) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: InheritedTypeSyntax) -> InheritedTypeSyntax {
            let typeName = node.typeName
            guard
                typeName.is(ClassRestrictionTypeSyntax.self),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return super.visit(
                node.with(
                    \.typeName,
                    TypeSyntax(
                        SimpleTypeIdentifierSyntax(name: .identifier("AnyObject"), genericArgumentClause: nil)
                            .with(\.leadingTrivia, typeName.leadingTrivia)
                            .with(\.trailingTrivia, typeName.trailingTrivia)
                    )
                )
            )
        }
    }
}
