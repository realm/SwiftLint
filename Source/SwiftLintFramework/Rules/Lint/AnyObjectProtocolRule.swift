import SwiftSyntax

private let warnDeprecatedOnceImpl: Void = {
    queuedPrintError("""
        The `anyobject_protocol` rule is now deprecated and will be completely removed in a future release.
        """
    )
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

struct AnyObjectProtocolRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "anyobject_protocol",
        name: "AnyObject Protocol",
        description: "Prefer using `AnyObject` over `class` for class-only protocols.",
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
                node.withTypeName(
                    TypeSyntax(
                        SimpleTypeIdentifierSyntax(name: .identifier("AnyObject"), genericArgumentClause: nil)
                            .withLeadingTrivia(typeName.leadingTrivia ?? .zero)
                            .withTrailingTrivia(typeName.trailingTrivia ?? .zero)
                    )
                )
            )
        }
    }
}
