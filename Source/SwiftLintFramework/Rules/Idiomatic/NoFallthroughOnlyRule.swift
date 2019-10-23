import Foundation
import SourceKittenFramework

public struct NoFallthroughOnlyRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_fallthrough_only",
        name: "No Fallthrough Only",
        description: "Fallthroughs can only be used if the `case` contains at least one other statement.",
        kind: .idiomatic,
        nonTriggeringExamples: NoFallthroughOnlyRuleExamples.nonTriggeringExamples,
        triggeringExamples: NoFallthroughOnlyRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .case,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let nsstring = file.contents.bridge(),
            let range = nsstring.byteRangeToNSRange(start: offset, length: length),
            let colonLocation = findCaseColon(text: nsstring, range: range)
        else {
            return []
        }

        let caseBodyRange = NSRange(location: colonLocation,
                                    length: range.length + range.location - colonLocation)
        let nonCommentCaseBody = file.match(pattern: "\\w+", range: caseBodyRange).filter { _, syntaxKinds in
            return !Set(syntaxKinds).subtracting(SyntaxKind.commentKinds).isEmpty
        }

        guard nonCommentCaseBody.count == 1 else {
            return []
        }

        let nsRange = nonCommentCaseBody[0].0
        if nsstring.substring(with: nsRange) == "fallthrough" && nonCommentCaseBody[0].1 == [.keyword] &&
            !isNextTokenUnknownAttribute(afterOffset: offset + length, file: file) {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, characterOffset: nsRange.location))]
        }

        return []
    }

    private func isNextTokenUnknownAttribute(afterOffset offset: Int, file: File) -> Bool {
        let nextNonCommentToken = file.syntaxMap.tokens
            .first { token in
                guard let kind = SyntaxKind(rawValue: token.type), !kind.isCommentLike else {
                    return false
                }

                return token.offset > offset
            }

        return (nextNonCommentToken?.type).flatMap(SyntaxKind.init(rawValue:)) == .attributeID &&
            nextNonCommentToken.flatMap(file.contents(for:)) == "@unknown"
    }

    // Find the first colon that exists outside of all enclosing delimiters
    private func findCaseColon(text: NSString, range: NSRange) -> Int? {
        var nParen = 0
        var nBrace = 0
        var nBrack = 0
        for index in range.location..<(range.location + range.length) {
            let char = text.substring(with: NSRange(location: index, length: 1))
            if char == "(" {
                nParen += 1
            }
            if char == ")" {
                nParen -= 1
            }
            if char == "[" {
                nBrack += 1
            }
            if char == "]" {
                nBrack -= 1
            }
            if char == "{" {
                nBrace += 1
            }
            if char == "}" {
                nBrace -= 1
            }

            if nParen == 0 && nBrack == 0 && nBrace == 0 && char == ":" {
                return index
            }
        }
        return nil
    }
}
