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

public struct AnyObjectProtocolRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        warnDeprecatedOnce()
        return Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension AnyObjectProtocolRule {
    private final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: ClassRestrictionTypeSyntax) {
            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
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

        override func visit(_ node: InheritedTypeSyntax) -> Syntax {
            let typeName = node.typeName
            guard typeName.is(ClassRestrictionTypeSyntax.self) else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
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
