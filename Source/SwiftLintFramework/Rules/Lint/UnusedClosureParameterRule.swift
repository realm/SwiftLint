import Foundation
import SourceKittenFramework

public struct UnusedClosureParameterRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _.",
        kind: .lint,
        nonTriggeringExamples: UnusedClosureParameterRuleExamples.nonTriggering,
        triggeringExamples: UnusedClosureParameterRuleExamples.triggering,
        corrections: UnusedClosureParameterRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { range, name in
            let reason = "Unused parameter \"\(name)\" in a closure should be replaced with _."
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { $0.range }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "_")
    }

    private func violationRanges(in file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                 kind: SwiftExpressionKind) -> [(range: NSRange, name: String)] {
        guard kind == .closure,
            let offset = dictionary.bodyOffset,
            let length = dictionary.bodyLength,
            length > 0
        else {
            return []
        }

        let byteRange = ByteRange(location: offset, length: length)
        let parameters = dictionary.enclosedVarParameters
        let contents = file.stringView

        return parameters.compactMap { param -> (NSRange, String)? in
            self.rangeAndName(parameter: param, contents: contents, byteRange: byteRange, file: file)
        }
    }

    private func rangeAndName(parameter: SourceKittenDictionary, contents: StringView, byteRange: ByteRange,
                              file: SwiftLintFile) -> (range: NSRange, name: String)? {
        guard let paramOffset = parameter.offset,
            let name = parameter.name?.replacingOccurrences(of: "$", with: "\\$?"),
            name != "_",
            let regex = try? NSRegularExpression(pattern: name, options: []),
            let range = contents.byteRangeToNSRange(byteRange)
        else {
            return nil
        }

        let paramLength = ByteCount(name.lengthOfBytes(using: .utf8))

        let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
        for range in matches {
            guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                              length: range.length),
                // if it's the parameter declaration itself, we should skip
                byteRange.location > (paramOffset + 1), // + 1 to handle backticks
                case let tokens = file.syntaxMap.tokens(inByteRange: byteRange)
            else {
                continue
            }

            let token = tokens.first(where: { token -> Bool in
                let isIdentifierOrSelf = token.kind == .identifier || (token.kind == .keyword && name == "self")
                guard isIdentifierOrSelf else { return false }

                let locationAndLengthMatch = token.offset == byteRange.location && token.length == byteRange.length
                if locationAndLengthMatch { return true }

                // Handle backticks
                let locationAndLengthMatchForBackticks = (token.offset == byteRange.location - 1) &&
                    (token.length == byteRange.length + 2)
                if
                    locationAndLengthMatchForBackticks,
                    let tokenContents = file.contents(for: token),
                    tokenContents.hasPrefix("`"),
                    tokenContents.hasSuffix("`")
                {
                    return true
                }

                return false
            })

            // found a usage, there's no violation!
            guard token == nil else {
                return nil
            }
        }
        let violationByteRange = ByteRange(location: paramOffset, length: paramLength)
        return contents.byteRangeToNSRange(violationByteRange).map { range in
            return (range, name)
        }
    }
}
