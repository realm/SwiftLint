import Foundation
import SourceKittenFramework

struct MultilineParametersBracketsRule: OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "multiline_parameters_brackets",
        name: "Multiline Parameters Brackets",
        description: "Multiline parameters should have their surrounding brackets in a new line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            func foo(param1: String, param2: String, param3: String)
            """),
            Example("""
            func foo(
                param1: String, param2: String, param3: String
            )
            """),
            Example("""
            func foo(
                param1: String,
                param2: String,
                param3: String
            )
            """),
            Example("""
            class SomeType {
                func foo(param1: String, param2: String, param3: String)
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String, param2: String, param3: String
                )
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String
                )
            }
            """),
            Example("""
            func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
            """),
            Example("""
                func foo(a: [Int] = [
                    1
                ])
            """)
        ],
        triggeringExamples: [
            Example("""
            func foo(↓param1: String, param2: String,
                     param3: String
            )
            """),
            Example("""
            func foo(
                param1: String,
                param2: String,
                param3: String↓)
            """),
            Example("""
            class SomeType {
                func foo(↓param1: String, param2: String,
                         param3: String
                )
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String↓)
            }
            """),
            Example("""
            func foo<T>(↓param1: T, param2: String,
                     param3: String
            ) -> T
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violations(in: file.structureDictionary, file: file)
    }

    private func violations(in substructure: SourceKittenDictionary, file: SwiftLintFile) -> [StyleViolation] {
        var violations = [StyleViolation]()

        // find violations at current level
        if let kind = substructure.declarationKind,
            SwiftDeclarationKind.functionKinds.contains(kind) {
            guard
                let nameOffset = substructure.nameOffset,
                let nameLength = substructure.nameLength,
                case let nameByteRange = ByteRange(location: nameOffset, length: nameLength),
                let functionName = file.stringView.substringWithByteRange(nameByteRange)
            else {
                return []
            }

            let parameters = substructure.substructure.filter { $0.declarationKind == .varParameter }
            let parameterBodies = parameters.compactMap { $0.content(in: file) }
            let parametersNewlineCount = parameterBodies.map { body in
                return body.countOccurrences(of: "\n")
            }.reduce(0, +)
            let declarationNewlineCount = functionName.countOccurrences(of: "\n")
            let isMultiline = declarationNewlineCount > parametersNewlineCount

            if isMultiline && parameters.isNotEmpty {
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

    private func openingBracketViolation(parameters: [SourceKittenDictionary],
                                         file: SwiftLintFile) -> StyleViolation? {
        guard
            let firstParamByteRange = parameters.first?.byteRange,
            let firstParamRange = file.stringView.byteRangeToNSRange(firstParamByteRange)
        else {
            return nil
        }

        let prefix = file.stringView.nsString.substring(to: firstParamRange.lowerBound)
        let invalidRegex = regex("\\([ \\t]*\\z")

        guard let invalidMatch = invalidRegex.firstMatch(in: prefix, options: [], range: prefix.fullNSRange) else {
            return nil
        }

        return StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: invalidMatch.range.location + 1)
        )
    }

    private func closingBracketViolation(parameters: [SourceKittenDictionary],
                                         file: SwiftLintFile) -> StyleViolation? {
        guard
            let lastParamByteRange = parameters.last?.byteRange,
            let lastParamRange = file.stringView.byteRangeToNSRange(lastParamByteRange)
        else {
            return nil
        }

        let suffix = file.stringView.nsString.substring(from: lastParamRange.upperBound)
        let invalidRegex = regex("\\A[ \\t]*\\)")

        guard let invalidMatch = invalidRegex.firstMatch(in: suffix, options: [], range: suffix.fullNSRange) else {
            return nil
        }

        let characterOffset = lastParamRange.upperBound + invalidMatch.range.upperBound - 1
        return StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: characterOffset)
        )
    }
}
