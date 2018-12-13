import Foundation
import SourceKittenFramework

public struct PrivateOverFilePrivateRule: Rule, ConfigurationProviderRule, CorrectableRule {
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

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        let syntaxTokens = file.syntaxMap.tokens
        let contents = file.contents.bridge()

        return file.structure.dictionary.substructure.compactMap { dictionary -> NSRange? in
            guard let offset = dictionary.offset else {
                return nil
            }

            if !configuration.validateExtensions &&
                dictionary.kind.flatMap(SwiftDeclarationKind.init) == .extension {
                return nil
            }

            let parts = syntaxTokens.prefix { offset > $0.offset }
            guard let lastKind = parts.last,
                SyntaxKind(rawValue: lastKind.type) == .attributeBuiltin,
                let aclName = contents.substringWithByteRange(start: lastKind.offset, length: lastKind.length),
                AccessControlLevel(description: aclName) == .fileprivate,
                let range = contents.byteRangeToNSRange(start: lastKind.offset, length: lastKind.length) else {
                    return nil
            }

            return range
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "private")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
