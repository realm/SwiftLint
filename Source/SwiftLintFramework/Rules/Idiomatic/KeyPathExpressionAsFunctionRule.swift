import Foundation
import SourceKittenFramework

public struct KeyPathExpressionAsFunctionRule: ASTRule, CorrectableRule, OptInRule,
                                               ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "key_path_expression_as_function",
        name: "Key Path Expression as Function",
        description: "Prefer using key paths instead of closures when possible.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotTwo,
        nonTriggeringExamples: [
            Example(#"let emails = users.map(\.email)"#),
            Example(#"let admins = users.filter(\.isAdmin)"#),
            Example("let all = users.filter { _ in true }"),
            Example("let emails = users.map { $0.email() }"),
            Example("""
            let violatingRanges = violatingRanges.filter { range in
                let region = fileRegions.first {
                    $0.contains(Location(file: self, characterOffset: range.location))
                }
                return region?.isRuleEnabled(rule) ?? true
            }
            """),
            Example("let ones = values.filter { $0 == 1 }")
        ],
        triggeringExamples: [
            Example("let emails = users.map ↓{ $0.email }"),
            Example("let emails = users.map(↓{ $0.email })"),
            Example("let admins = users.filter(where: ↓{ $0.isAdmin })")
        ],
        corrections: [
            Example("let emails = users.map(↓{ $0.email })"):
                Example(#"let emails = users.map(\.email)"#),
            Example("let admins = users.filter(where: ↓{ $0.isAdmin })"):
                Example(#"let admins = users.filter(where: \.isAdmin)"#)
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftVersion.current >= Self.description.minSwiftVersion else {
            return []
        }

        return violations(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0.offset))
        }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        guard SwiftVersion.current >= Self.description.minSwiftVersion else {
            return []
        }

        let violations = file.structureDictionary
            .traverseDepthFirst { subDict -> [ViolationInfo] in
                guard let kind = self.kind(from: subDict) else { return [] }
                return self.violations(in: file, kind: kind, dictionary: subDict)
            }.filter { info in
                guard let range = info.rangeToReplace else {
                    return false
                }
                return !file.ruleEnabled(violatingRanges: [range], for: self).isEmpty
            }

        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violation in violations.reversed() {
            guard let rangeToReplace = violation.rangeToReplace else {
                continue
            }

            if let indexRange = correctedContents.nsrangeToIndexRange(rangeToReplace) {
                let correction = "\\" + violation.keyPathContent
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: correction)
                adjustedLocations.insert(rangeToReplace.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: Self.description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func violations(in file: SwiftLintFile,
                            kind: SwiftExpressionKind,
                            dictionary: SourceKittenDictionary) -> [ViolationInfo] {
        guard kind == .call else {
            return []
        }

        let closures = dictionary.substructure.compactMap { dictionary -> SourceKittenDictionary? in
            if dictionary.isClosure {
                return dictionary
            }

            if dictionary.isClosureArgument {
                return dictionary.substructure.first
            }

            return nil
        }

        let isTrailingClosure = isTrailingClosureCall(dictionary: dictionary, file: file)

        return closures.compactMap { closureDictionary -> ViolationInfo? in
            guard closureDictionary.enclosedVarParameters.isEmpty,
                  let bodyRange = closureDictionary.bodyByteRange,
                  bodyRange.length > 0,
                  let offset = closureDictionary.offset,
                  let byteRange = closureDictionary.byteRange,
                  let searchRange = file.stringView.byteRangeToNSRange(bodyRange) else {
                return nil
            }

            // Right now, this rule only catches cases where $0 is used (instead of named parameters) for simplicity
            let pattern =  #"\A\s*\$0(\.\w+)\b\s*\z"#
            return file
                .matchesAndSyntaxKinds(matching: pattern, range: searchRange)
                .compactMap { textCheckingResult, syntaxKinds in
                    guard syntaxKinds == [.identifier, .identifier] else {
                        return nil
                    }

                    let keyPathContent = file.stringView.substring(with: textCheckingResult.range(at: 1))
                    let rangeToReplace = isTrailingClosure ? nil : file.stringView.byteRangeToNSRange(byteRange)
                    return ViolationInfo(offset: offset, rangeToReplace: rangeToReplace, keyPathContent: keyPathContent)
                }
                .first
        }
    }

    private func isTrailingClosureCall(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            case let start = min(offset, offset + length - 1),
            case let byteRange = ByteRange(location: start, length: length),
            let text = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return !text.hasSuffix(")")
    }

    private struct ViolationInfo {
        let offset: ByteCount
        let rangeToReplace: NSRange?
        let keyPathContent: String
    }
}

private extension SourceKittenDictionary {
    var isClosure: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .closure
    }

    var isClosureArgument: Bool {
        return kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .argument &&
            substructure.count == 1 &&
            substructure.allSatisfy(\.isClosure)
    }
}
