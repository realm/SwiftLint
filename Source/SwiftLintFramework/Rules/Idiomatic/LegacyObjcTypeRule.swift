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

struct LegacyObjcTypeRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
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
            Example(#"_ = ↓NSNotification.Name("com.apple.Music.playerInfo")"#),
            Example(#"""
            let keyValuePair: (Int) -> (↓NSString, ↓NSString) = {
              let n = "\($0)" as ↓NSString; return (n, n)
            }
            dictionary = [↓NSString: ↓NSString](uniqueKeysWithValues:
              (1...10_000).lazy.map(keyValuePair))
            """#),
            Example("""
            extension Foundation.Notification.Name {
                static var reachabilityChanged: Foundation.↓NSNotification.Name {
                    return Foundation.Notification.Name("org.wordpress.reachability.changed")
                }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
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

        override func visitPost(_ node: IdentifierExprSyntax) {
            if legacyObjcTypes.contains(node.identifier.text) {
                violations.append(node.identifier.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: MemberTypeIdentifierSyntax) {
            guard node.baseType.as(SimpleTypeIdentifierSyntax.self)?.typeName == "Foundation",
               legacyObjcTypes.contains(node.name.text)
            else {
                return
            }

            violations.append(node.name.positionAfterSkippingLeadingTrivia)
        }
    }
}
