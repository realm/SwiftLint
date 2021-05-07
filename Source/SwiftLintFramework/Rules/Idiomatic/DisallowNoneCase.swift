import Foundation
import SourceKittenFramework

public struct DisallowNoneCase: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "disallow_none_case",
        name: "Disallow None Case",
        description: "Disallows the naming of enum cases as 'none' which can conflict with Optional<T>.none",
        kind: .idiomatic
    )

    public func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard kind.isForValidating && dictionary.isNameInvalid, let offset = dictionary.offset else { return [] }
        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: offset),
                reason: """
\(kind.reasonPrefix) should not be named `none` since the compiler can think you mean `Optional<T>.none when checking equality`.
"""
            )
        ]
    }
}

private extension SwiftDeclarationKind {
    var isForValidating: Bool { self == .enumcase || self == .varClass || self == .varStatic }

    var reasonPrefix: String {
        switch self {
        case .enum: return "`case`"
        case .varClass, .varStatic: return "`static`/`class` members"
        default: return ""
        }
    }
}

private extension SourceKittenDictionary {
    var isNameInvalid: Bool { name == "none" }
}
