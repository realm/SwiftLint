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
            func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
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
        if let kindString = substructure.kind, let kind = SwiftDeclarationKind(rawValue: kindString),
            SwiftDeclarationKind.functionKinds.contains(kind) {
            guard
                let nameOffset = substructure.nameOffset,
                let nameLength = substructure.nameLength,
                let functionName = file.contents.bridge().substringWithByteRange(start: nameOffset, length: nameLength)
            else {
                return []
            }

            let isMultiline = functionName.contains("\n")

            let parameters = substructure.substructure.filter { $0.kind == SwiftDeclarationKind.varParameter.rawValue }
            if isMultiline && !parameters.isEmpty {
                if let openingBracketViolation = openingBracketViolation(parameters: parameters, file: file) {
                    violations.append(openingBracketViolation)
                }

                if let closingBracketViolation = closingBracketViolation(parameters: parameters, file: file) {
                    violations.append(closingBracketViolation)
                }
            }
        }

        // find violations at deeper levels
        for substructure in substructure.substructure {
            violations += self.violations(in: substructure, file: file)
        }

        return violations
    }

    private func openingBracketViolation(parameters: [[String: SourceKitRepresentable]],
                                         file: File) -> StyleViolation? {
        guard
            let firstParamByteOffset = parameters.first?.offset,
            let firstParamByteLength = parameters.first?.length,
            let firstParamRange = file.contents.bridge().byteRangeToNSRange(
                start: firstParamByteOffset,
                length: firstParamByteLength
            )
        else {
                return nil
        }

        let prefix = file.contents.bridge().substring(to: firstParamRange.lowerBound)
        let invalidRegex = regex("\\([ \\t]*\\z")

        guard let invalidMatch = invalidRegex.firstMatch(in: prefix, options: [], range: prefix.fullNSRange) else {
            return nil
        }

        return StyleViolation(
            ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: invalidMatch.range.location + 1)
        )
    }

    private func closingBracketViolation(parameters: [[String: SourceKitRepresentable]],
                                         file: File) -> StyleViolation? {
        guard
            let lastParamByteOffset = parameters.last?.offset,
            let lastParamByteLength = parameters.last?.length,
            let lastParamRange = file.contents.bridge().byteRangeToNSRange(
                start: lastParamByteOffset,
                length: lastParamByteLength
            )
        else {
            return nil
        }

        let suffix = file.contents.bridge().substring(from: lastParamRange.upperBound)
        let invalidRegex = regex("\\A[ \\t]*\\)")

        guard let invalidMatch = invalidRegex.firstMatch(in: suffix, options: [], range: suffix.fullNSRange) else {
            return nil
        }

        let characterOffset = lastParamRange.upperBound + invalidMatch.range.upperBound - 1
        return StyleViolation(
            ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: characterOffset)
        )
    }
}
