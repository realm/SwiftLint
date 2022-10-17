import SwiftSyntax

private let legacyObjcTypes = [
    "NSAffineTransform",
    "NSArray",
    "NSCalendar",
    "NSCharacterSet",
    "NSData",
    "NSDateComponents",
    "NSDateInterval",
    "NSDate",
    "NSDecimalNumber",
    "NSDictionary",
    "NSIndexPath",
    "NSIndexSet",
    "NSLocale",
    "NSMeasurement",
    "NSNotification",
    "NSNumber",
    "NSPersonNameComponents",
    "NSSet",
    "NSString",
    "NSTimeZone",
    "NSURL",
    "NSURLComponents",
    "NSURLQueryItem",
    "NSURLRequest",
    "NSUUID"
]

public struct LegacyObjcTypeRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_objc_type",
        name: "Legacy Objective-C Reference Type",
        description: "Prefer Swift value types to bridged Objective-C reference types",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var array = Array<Int>()\n"),
            Example("var calendar: Calendar? = nil"),
            Example("var formatter: NSDataDetector"),
            Example("var className: String = NSStringFromClass(MyClass.self)"),
            Example("_ = URLRequest.CachePolicy.reloadIgnoringLocalCacheData"),
            Example(#"_ = Notification.Name("com.apple.Music.playerInfo")"#)
        ],
        triggeringExamples: [
            Example("var array = ↓NSArray()"),
            Example("var calendar: ↓NSCalendar? = nil"),
            Example("_ = ↓NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData"),
            Example(#"_ = ↓NSNotification.Name("com.apple.Music.playerInfo")"#)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension LegacyObjcTypeRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: SimpleTypeIdentifierSyntax) {
            if let typeName = node.typeName, legacyObjcTypes.contains(typeName) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let identifierText = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
                legacyObjcTypes.contains(identifierText)
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard
                let identifierText = node.base?.as(IdentifierExprSyntax.self)?.identifier.text,
                legacyObjcTypes.contains(identifierText)
            else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
