import Foundation
import SourceKittenFramework

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

public struct LegacyObjcTypeRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_objc_type",
        name: "Legacy Objective-C Reference Type",
        description: "Prefer Swift value types to bridged Objective-C reference types",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var array = Array<Int>()\n"),
            Example("var calendar: Calendar? = nil")
        ],
        triggeringExamples: [
            Example("var array = NSArray()"),
            Example("var calendar: NSCalendar? = nil")
        ]
    )

    private let pattern = legacyObjcTypes.joined(separator: "|")

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: pattern)
            .filter { !Set($0.1).isDisjoint(with: [.typeidentifier, .identifier]) }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.0.location))
            }
    }
}
