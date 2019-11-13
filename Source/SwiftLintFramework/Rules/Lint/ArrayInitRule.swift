import Foundation
import SourceKittenFramework

public struct ArrayInitRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "array_init",
        name: "Array Init",
        description: "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array.",
        kind: .lint,
        nonTriggeringExamples: [
            "Array(foo)\n",
            "foo.map { $0.0 }\n",
            "foo.map { $1 }\n",
            "foo.map { $0() }\n",
            "foo.map { ((), $0) }\n",
            "foo.map { $0! }\n",
            "foo.map { $0! /* force unwrap */ }\n",
            "foo.something { RouteMapper.map($0) }\n",
            "foo.map { !$0 }\n",
            "foo.map { /* a comment */ !$0 }\n"
        ],
        triggeringExamples: [
            "↓foo.map({ $0 })\n",
            "↓foo.map { $0 }\n",
            "↓foo.map { return $0 }\n",
            "↓foo.map { elem in\n" +
            "   elem\n" +
            "}\n",
            "↓foo.map { elem in\n" +
            "   return elem\n" +
            "}\n",
            "↓foo.map { (elem: String) in\n" +
                "   elem\n" +
            "}\n",
            "↓foo.map { elem -> String in\n" +
            "   elem\n" +
            "}\n",
            "↓foo.map { $0 /* a comment */ }\n",
            "↓foo.map { /* a comment */ $0 }\n"
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call, let name = dictionary.name, name.hasSuffix(".map"),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let offset = dictionary.offset else {
                return []
        }

        let range = NSRange(location: bodyOffset, length: bodyLength)
        let tokens = file.syntaxMap.tokens(inByteRange: range).filter { token in
            guard let kind = token.kind else {
                return false
            }

            return !SyntaxKind.commentKinds.contains(kind)
        }

        guard let firstToken = tokens.first,
            case let nameEndPosition = nameOffset + nameLength,
            isClosureParameter(firstToken: firstToken, nameEndPosition: nameEndPosition, file: file),
            isShortParameterStyleViolation(file: file, tokens: tokens) ||
            isParameterStyleViolation(file: file, dictionary: dictionary, tokens: tokens),
            let lastToken = tokens.last,
            case let bodyEndPosition = bodyOffset + bodyLength,
            !containsTrailingContent(lastToken: lastToken, bodyEndPosition: bodyEndPosition, file: file),
            !containsLeadingContent(tokens: tokens, bodyStartPosition: bodyOffset, file: file) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClosureParameter(firstToken: SwiftLintSyntaxToken,
                                    nameEndPosition: Int,
                                    file: SwiftLintFile) -> Bool {
        let length = firstToken.offset - nameEndPosition
        guard length > 0,
            case let contents = file.linesContainer,
            let byteRange = contents.byteRangeToNSRange(start: nameEndPosition, length: length) else {
                return false
        }

        let pattern = regex("\\A\\s*\\(?\\s*\\{")
        return pattern.firstMatch(in: file.contents, options: .anchored, range: byteRange) != nil
    }

    private func containsTrailingContent(lastToken: SwiftLintSyntaxToken,
                                         bodyEndPosition: Int,
                                         file: SwiftLintFile) -> Bool {
        let lastTokenEnd = lastToken.offset + lastToken.length
        let remainingLength = bodyEndPosition - lastTokenEnd
        let remainingRange = NSRange(location: lastTokenEnd, length: remainingLength)
        return containsContent(inByteRange: remainingRange, file: file)
    }

    private func containsLeadingContent(tokens: [SwiftLintSyntaxToken],
                                        bodyStartPosition: Int,
                                        file: SwiftLintFile) -> Bool {
        let inTokenPosition = tokens.firstIndex(where: { token in
            token.kind == .keyword && file.contents(for: token) == "in"
        })

        let firstToken: SwiftLintSyntaxToken
        let start: Int
        if let position = inTokenPosition {
            let index = tokens.index(after: position)
            firstToken = tokens[index]
            let inToken = tokens[position]
            start = inToken.offset + inToken.length
        } else {
            firstToken = tokens[0]
            start = bodyStartPosition
        }

        let length = firstToken.offset - start
        let remainingRange = NSRange(location: start, length: length)
        return containsContent(inByteRange: remainingRange, file: file)
    }

    private func containsContent(inByteRange byteRange: NSRange, file: SwiftLintFile) -> Bool {
        let nsstring = file.contents.bridge()
        let remainingTokens = file.syntaxMap.tokens(inByteRange: byteRange)
        let ranges = NSMutableIndexSet(indexesIn: byteRange)

        for token in remainingTokens {
            ranges.remove(in: token.range)
        }

        var containsContent = false
        ranges.enumerateRanges(options: []) { range, stop in
            guard let substring = nsstring.substringWithByteRange(start: range.location, length: range.length) else {
                return
            }

            let processedSubstring = substring
                .trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !processedSubstring.isEmpty {
                stop.pointee = true
                containsContent = true
            }
        }

        return containsContent
    }

    private func isShortParameterStyleViolation(file: SwiftLintFile, tokens: [SwiftLintSyntaxToken]) -> Bool {
        let kinds = tokens.kinds
        switch kinds {
        case [.identifier]:
            let identifier = file.contents(for: tokens[0])
            return identifier == "$0"
        case [.keyword, .identifier]:
            let keyword = file.contents(for: tokens[0])
            let identifier = file.contents(for: tokens[1])
            return keyword == "return" && identifier == "$0"
        default:
            return false
        }
    }

    private func isParameterStyleViolation(file: SwiftLintFile, dictionary: SourceKittenDictionary,
                                           tokens: [SwiftLintSyntaxToken]) -> Bool {
        let parameters = dictionary.enclosedVarParameters
        guard parameters.count == 1,
            let offset = parameters[0].offset,
            let length = parameters[0].length,
            let parameterName = parameters[0].name else {
                return false
        }

        let parameterEnd = offset + length
        let tokens = Array(tokens.filter { $0.offset >= parameterEnd }.drop { token in
            let isKeyword = token.kind == .keyword
            return !isKeyword || file.contents(for: token) != "in"
        })

        let kinds = tokens.kinds
        switch kinds {
        case [.keyword, .identifier]:
            let keyword = file.contents(for: tokens[0])
            let identifier = file.contents(for: tokens[1])
            return keyword == "in" && identifier == parameterName
        case [.keyword, .keyword, .identifier]:
            let firstKeyword = file.contents(for: tokens[0])
            let secondKeyword = file.contents(for: tokens[1])
            let identifier = file.contents(for: tokens[2])
            return firstKeyword == "in" && secondKeyword == "return" && identifier == parameterName
        default:
            return false
        }
    }
}

private extension Array where Element == SyntaxKind {
    static func ~= (array: [SyntaxKind], value: [SyntaxKind]) -> Bool {
        return array == value
    }
}
