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
    "NSUUID",
]

@SwiftSyntaxRule(optIn: true)
struct LegacyObjcTypeRule: Rule {
    var configuration = LegacyObjcTypeConfiguration()

    static let description = RuleDescription(
        identifier: "legacy_objc_type",
        name: "Legacy Objective-C Reference Type",
        description: "Prefer Swift value types to bridged Objective-C reference types",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "var array = Array<Int>()",
            "var calendar: Calendar? = nil",
            "var formatter: NSDataDetector",
            "var className: String = NSStringFromClass(MyClass.self)",
            "_ = URLRequest.CachePolicy.reloadIgnoringLocalCacheData",
            #"_ = Notification.Name("com.apple.Music.playerInfo")"#,
            """
            class SLURLRequest: NSURLRequest {
                let data = NSData()
                let number: NSNumber
            }
            """.configuration(["allowed_types": ["NSData", "NSNumber", "NSURLRequest"]]),
        ]),
        triggeringExamples: #examples([
            "var array = ↓NSArray()",
            "var calendar: ↓NSCalendar? = nil",
            "_ = ↓NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData",
            #"_ = ↓NSNotification.Name("com.apple.Music.playerInfo")"#,
            #"""
            let keyValuePair: (Int) -> (↓NSString, ↓NSString) = {
              let n = "\($0)" as ↓NSString; return (n, n)
            }
            dictionary = [↓NSString: ↓NSString](uniqueKeysWithValues:
              (1...10_000).lazy.map(keyValuePair))
            """#,
            """
            extension Foundation.Notification.Name {
                static var reachabilityChanged: Foundation.↓NSNotification.Name {
                    return Foundation.Notification.Name("org.wordpress.reachability.changed")
                }
            }
            """,
        ])
    )
}

private extension LegacyObjcTypeRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IdentifierTypeSyntax) {
            if let name = node.typeName, isViolatingType(name) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if isViolatingType(node.baseName.text) {
                violations.append(node.baseName.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: MemberTypeSyntax) {
            if node.baseType.as(IdentifierTypeSyntax.self)?.typeName == "Foundation", isViolatingType(node.name.text) {
                violations.append(node.name.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isViolatingType(_ name: String) -> Bool {
            legacyObjcTypes.contains(name) && !configuration.allowedTypes.contains(name)
        }
    }
}
