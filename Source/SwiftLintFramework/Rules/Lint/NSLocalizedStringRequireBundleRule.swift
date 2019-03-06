import Foundation
import SourceKittenFramework

public struct NSLocalizedStringRequireBundleRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_require_bundle",
        name: "NSLocalizedString Require Bundle",
        description: "Calls to NSLocalisedString should specify the bundle which contains the strings file.",
        kind: .lint,
        nonTriggeringExamples: [
            """
            NSLocalizedString("someKey", bundle: .main, comment: "test")
            """,
            """
            NSLocalizedString("someKey", tableName: "a",
                              bundle: Bundle(for: A.self),
                              comment: "test")
            """,
            """
            NSLocalizedString("someKey", tableName: "xyz",
                              bundle: someBundle, value: "test"
                              comment: "test")
            """,
            """
            arbitraryFunctionCall("something")
            """
        ],
        triggeringExamples: [
            """
            ↓NSLocalizedString("someKey", comment: "test")
            """,
            """
            ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
            """,
            """
            ↓NSLocalizedString("someKey", tableName: "xyz",
                              value: "test", comment: "test")
            """
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return []
    }
}
