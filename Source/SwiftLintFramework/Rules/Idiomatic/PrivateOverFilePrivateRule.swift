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
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("public \n enum MyEnum {}"),
            Example("open extension \n String {}"),
            Example("internal extension String {}"),
            Example("""
            extension String {
              fileprivate func Something(){}
            }
            """),
            Example("""
            class MyClass {
              fileprivate let myInt = 4
            }
            """),
            Example("""
            class MyClass {
              fileprivate(set) var myInt = 4
            }
            """),
            Example("""
            struct Outter {
              struct Inter {
                fileprivate struct Inner {}
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓fileprivate enum MyEnum {}"),
            Example("""
            ↓fileprivate class MyClass {
              fileprivate(set) var myInt = 4
            }
            """)
        ],
        corrections: [
            Example("↓fileprivate enum MyEnum {}"): Example("private enum MyEnum {}"),
            Example("↓fileprivate class MyClass {\nfileprivate(set) var myInt = 4\n}"):
                Example("private class MyClass {\nfileprivate(set) var myInt = 4\n}")
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
        let contents = file.stringView

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
                let aclName = contents.substringWithByteRange(lastKind.range),
                AccessControlLevel(description: aclName) == .fileprivate,
                let range = contents.byteRangeToNSRange(lastKind.range)
            else {
                return nil
            }

            return range
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "private")
    }
}
