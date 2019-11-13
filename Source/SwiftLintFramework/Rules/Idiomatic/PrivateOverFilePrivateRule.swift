import Foundation
import SourceKittenFramework

public struct PrivateOverFilePrivateRule: ConfigurationProviderRule, SubstitutionCorrectableRule {
    public var configuration = PrivateOverFilePrivateRuleConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "private_over_fileprivate",
        name: "Private over fileprivate",
        description: "Prefer `private` over `fileprivate` declarations.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "private extension String {}",
            "public \n enum MyEnum {}",
            "open extension \n String {}",
            "internal extension String {}",
            """
            extension String {
              fileprivate func Something(){}
            }
            """,
            """
            class MyClass {
              fileprivate let myInt = 4
            }
            """,
            """
            class MyClass {
              fileprivate(set) var myInt = 4
            }
            """,
            """
            struct Outter {
              struct Inter {
                fileprivate struct Inner {}
              }
            }
            """
        ],
        triggeringExamples: [
            "↓fileprivate enum MyEnum {}",
            """
            ↓fileprivate class MyClass {
              fileprivate(set) var myInt = 4
            }
            """
        ],
        corrections: [
            "↓fileprivate enum MyEnum {}": "private enum MyEnum {}",
            "↓fileprivate class MyClass {\nfileprivate(set) var myInt = 4\n}":
                "private class MyClass {\nfileprivate(set) var myInt = 4\n}"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let syntaxTokens = file.syntaxMap.tokens
        let contents = file.linesContainer

        let dict = file.structureDictionary
        return dict.substructure.compactMap { dictionary -> NSRange? in
            guard let offset = dictionary.offset else {
                return nil
            }

            if !configuration.validateExtensions &&
                dictionary.declarationKind == .extension {
                return nil
            }

            let parts = syntaxTokens.prefix { offset > $0.offset }
            guard let lastKind = parts.last,
                lastKind.kind == .attributeBuiltin,
                let aclName = contents.substringWithByteRange(start: lastKind.offset, length: lastKind.length),
                AccessControlLevel(description: aclName) == .fileprivate,
                let range = contents.byteRangeToNSRange(start: lastKind.offset, length: lastKind.length) else {
                    return nil
            }

            return range
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        return (violationRange, "private")
    }
}
