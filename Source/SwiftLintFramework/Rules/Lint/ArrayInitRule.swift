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
            Example("Array(foo)\n"),
            Example("foo.map { $0.0 }\n"),
            Example("foo.map { $1 }\n"),
            Example("foo.map { $0() }\n"),
            Example("foo.map { ((), $0) }\n"),
            Example("foo.map { $0! }\n"),
            Example("foo.map { $0! /* force unwrap */ }\n"),
            Example("foo.something { RouteMapper.map($0) }\n"),
            Example("foo.map { !$0 }\n"),
            Example("foo.map { /* a comment */ !$0 }\n")
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 })\n"),
            Example("↓foo.map { $0 }\n"),
            Example("↓foo.map { return $0 }\n"),
            Example("↓foo.map { elem in\n" +
            "   elem\n" +
            "}\n"),
            Example("↓foo.map { elem in\n" +
            "   return elem\n" +
            "}\n"),
            Example("↓foo.map { (elem: String) in\n" +
                "   elem\n" +
            "}\n"),
            Example("↓foo.map { elem -> String in\n" +
            "   elem\n" +
            "}\n"),
            Example("↓foo.map { $0 /* a comment */ }\n"),
            Example("↓foo.map { /* a comment */ $0 }\n")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call, let name = dictionary.name, name.hasSuffix(".map"),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let bodyRange = dictionary.bodyByteRange,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let offset = dictionary.offset else {
                return []
        }

        let tokens = file.syntaxMap.tokens(inByteRange: bodyRange).filter { token in
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
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isClosureParameter(firstToken: SwiftLintSyntaxToken,
                                    nameEndPosition: ByteCount,
                                    file: SwiftLintFile) -> Bool {
        let length = firstToken.offset - nameEndPosition
        guard length > 0,
            case let contents = file.stringView,
            case let byteRange = ByteRange(location: nameEndPosition, length: length),
            let nsRange = contents.byteRangeToNSRange(byteRange)
        else {
            return false
        }

        let pattern = regex("\\A\\s*\\(?\\s*\\{")
        return pattern.firstMatch(in: file.contents, options: .anchored, range: nsRange) != nil
    }

    private func containsTrailingContent(lastToken: SwiftLintSyntaxToken,
                                         bodyEndPosition: ByteCount,
                                         file: SwiftLintFile) -> Bool {
        let lastTokenEnd = lastToken.offset + lastToken.length
        let remainingLength = bodyEndPosition - lastTokenEnd
        let remainingRange = ByteRange(location: lastTokenEnd, length: remainingLength)
        return containsContent(inByteRange: remainingRange, file: file)
    }

    private func containsLeadingContent(tokens: [SwiftLintSyntaxToken],
                                        bodyStartPosition: ByteCount,
                                        file: SwiftLintFile) -> Bool {
        let inTokenPosition = tokens.firstIndex(where: { token in
            token.kind == .keyword && file.contents(for: token) == "in"
        })

        let firstToken: SwiftLintSyntaxToken
        let start: ByteCount
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
        let remainingRange = ByteRange(location: start, length: length)
        return containsContent(inByteRange: remainingRange, file: file)
    }

    private func containsContent(inByteRange byteRange: ByteRange, file: SwiftLintFile) -> Bool {
        let stringView = file.stringView
        let remainingTokens = file.syntaxMap.tokens(inByteRange: byteRange)
        guard let nsRange = stringView.byteRangeToNSRange(byteRange) else {
            return false
        }

        let ranges = NSMutableIndexSet(indexesIn: nsRange)

        for tokenNSRange in remainingTokens.compactMap({ stringView.byteRangeToNSRange($0.range) }) {
            ranges.remove(in: tokenNSRange)
        }

        var containsContent = false
        ranges.enumerateRanges(options: []) { range, stop in
            let substring = stringView.substring(with: range)
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
