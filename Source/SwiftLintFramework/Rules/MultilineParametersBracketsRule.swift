import Foundation
import SourceKittenFramework

public struct MultilineParametersBracketsRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_parameters_brackets",
        name: "Multiline Parameters Brackets",
        description: "Multiline parameters should have their surrounding brackets in a new line.",
        kind: .style,
        nonTriggeringExamples: [
            """
            func foo(param1: String, param2: String, param3: String)
            """,
            """
            func foo(
                param1: String, param2: String, param3: String
            )
            """,
            """
            func foo(
                param1: String,
                param2: String,
                param3: String
            )
            """,
            """
            class SomeType {
                func foo(param1: String, param2: String, param3: String)
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String, param2: String, param3: String
                )
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String
                )
            }
            """,
            """
            func foo<T>(param1: T, param2: String, param3: String) -> T
            """
        ],
        triggeringExamples: [
            """
            func foo(↓param1: String, param2: String,
                     param3: String
            )
            """,
            """
            func foo(
                param1: String,
                param2: String,
                param3: String↓)
            """,
            """
            class SomeType {
                func foo(↓param1: String, param2: String,
                         param3: String
                )
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String↓)
            }
            """,
            """
            func foo<T>(↓param1: T, param2: String,
                     param3: String
            ) -> T
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violations(in: file.structure.dictionary, file: file)
    }

    private func violations(in substructure: [String: SourceKitRepresentable], file: File) -> [StyleViolation] {
        var violations = [StyleViolation]()

        // find violations at current level
        if
            let kindString = substructure.kind,
            let kind = SwiftDeclarationKind(rawValue: kindString),
            SwiftDeclarationKind.functionKinds.contains(kind)
        {
            let fileContents = file.contents.bridge()
            guard
                let byteOffset = substructure.offset,
                let byteLength = substructure.length,
                let range = fileContents.byteRangeToNSRange(start: byteOffset, length: byteLength)
            else {
                return []
            }

            let body = file.contents.substring(from: range.location, length: range.length)
            let isMultiline = body.contains("\n")

            let parameters = substructure.substructure.filter { $0.kind == SwiftDeclarationKind.varParameter.rawValue }
            if isMultiline && !parameters.isEmpty {
                if
                    let firstParamByteOffset = parameters.first?.offset,
                    let firstParamByteLength = parameters.first?.length,
                    let firstParamRange = file.contents.bridge().byteRangeToNSRange(
                        start: firstParamByteOffset,
                        length: firstParamByteLength
                    )
                {
                    let prefix = file.contents.bridge().substring(to: firstParamRange.lowerBound)
                    let invalidPrefixRegex = regex("\\([ \\t]*\\z")

                    if let invalidMatch = invalidPrefixRegex.firstMatch(in: prefix, options: [], range: prefix.fullNSRange) {
                        violations.append(StyleViolation(
                            ruleDescription: type(of: self).description,
                            severity: configuration.severity,
                            location: Location(file: file, characterOffset: invalidMatch.range.location + 1)
                        ))
                    }
                }

                if
                    let lastParamByteOffset = parameters.last?.offset,
                    let lastParamByteLength = parameters.last?.length,
                    let lastParamRange = file.contents.bridge().byteRangeToNSRange(
                        start: lastParamByteOffset,
                        length: lastParamByteLength
                    )
                {
                    let suffix = file.contents.bridge().substring(from: lastParamRange.upperBound)
                    let invalidSuffixRegex = regex("\\A[ \\t]*\\)")

                    if let invalidMatch = invalidSuffixRegex.firstMatch(in: suffix, options: [], range: suffix.fullNSRange) {
                        violations.append(StyleViolation(
                            ruleDescription: type(of: self).description,
                            severity: configuration.severity,
                            location: Location(file: file, characterOffset: lastParamRange.upperBound + invalidMatch.range.upperBound - 1)
                        ))
                    }
                }
            }
        }

        // find violations at deeper levels
        for substructure in substructure.substructure {
            violations += self.violations(in: substructure, file: file)
        }

        return violations
    }
}
