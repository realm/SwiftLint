import Foundation
import SourceKittenFramework

private enum TrailingCommaReason: String {
    case missingTrailingCommaReason = "Multi-line collection literals should have trailing commas."
    case extraTrailingCommaReason = "Collection literals should not have trailing commas."
}

private typealias CommaRuleViolation = (index: ByteCount, reason: TrailingCommaReason)

public struct TrailingCommaRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule {
    public var configuration = TrailingCommaConfiguration()

    public init() {}

    private static let triggeringExamples: [Example] = [
        Example("let foo = [1, 2, 3↓,]\n"),
        Example("let foo = [1, 2, 3↓, ]\n"),
        Example("let foo = [1, 2, 3   ↓,]\n"),
        Example("let foo = [1: 2, 2: 3↓, ]\n"),
        Example("struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n"),
        Example("let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n"),
        Example("let example = [ 1,\n2↓,\n // 3,\n]"),
        Example("let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]\n"),
        Example("class C {\n #if true\n func f() {\n let foo = [1, 2, 3↓,]\n }\n #endif\n}"),
        Example("foo([1: \"\\(error)\"↓,])\n")
    ]

    private static let corrections: [Example: Example] = {
        let fixed = triggeringExamples.map { example -> Example in
            let fixedString = example.code.replacingOccurrences(of: "↓,", with: "")
            return example.with(code: fixedString)
        }
        var result: [Example: Example] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()

    public static let description = RuleDescription(
        identifier: "trailing_comma",
        name: "Trailing Comma",
        description: "Trailing commas in arrays and dictionaries should be avoided/enforced.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = [1, 2, 3]\n"),
            Example("let foo = []\n"),
            Example("let foo = [:]\n"),
            Example("let foo = [1: 2, 2: 3]\n"),
            Example("let foo = [Void]()\n"),
            Example("let example = [ 1,\n 2\n // 3,\n]"),
            Example("foo([1: \"\\(error)\"])\n")
        ],
        triggeringExamples: Self.triggeringExamples,
        corrections: Self.corrections
    )

    private static let commaRegex = regex(",", options: [.ignoreMetacharacters])

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        if let (index, reason) = violationIndexAndReason(in: file, kind: kind, dictionary: dictionary) {
            return violations(file: file, byteOffset: index, reason: reason.rawValue)
        } else {
            return []
        }
    }

    public func violationRanges(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard let (offset, reason) = violationIndexAndReason(in: file, kind: kind, dictionary: dictionary),
            case let length: ByteCount = reason == .extraTrailingCommaReason ? 1 : 0,
            case let byteRange = ByteRange(location: offset, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange)
        else {
            return []
        }

        return [range]
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, configuration.mandatoryComma ? "," : "")
    }

    private func violationIndexAndReason(in file: SwiftLintFile, kind: SwiftExpressionKind,
                                         dictionary: SourceKittenDictionary) -> CommaRuleViolation? {
        let allowedKinds: Set<SwiftExpressionKind> = [.array, .dictionary]

        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            allowedKinds.contains(kind) else {
                return nil
        }

        let endPositions = dictionary.elements.compactMap { $0.byteRange?.upperBound }

        guard let lastPosition = endPositions.max(), bodyLength + bodyOffset >= lastPosition else {
            return nil
        }

        let contents = file.stringView
        if let (startLine, _) = contents.lineAndCharacter(forByteOffset: bodyOffset),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: lastPosition),
            configuration.mandatoryComma && startLine == endLine {
            // shouldn't trigger if mandatory comma style and is a single-line declaration
            return nil
        }

        let length = bodyLength + bodyOffset - lastPosition
        let byteRangeAfterLastElement = ByteRange(location: lastPosition, length: length)
        let contentsAfterLastElement = contents.substringWithByteRange(byteRangeAfterLastElement) ?? ""

        // if a trailing comma is not present
        guard let commaIndex = trailingCommaIndex(contents: contentsAfterLastElement, file: file, offset: lastPosition)
        else {
            guard configuration.mandatoryComma else {
                return nil
            }

            return (lastPosition, .missingTrailingCommaReason)
        }

        // trailing comma is present, which is a violation if mandatoryComma is false
        guard !configuration.mandatoryComma else {
            return nil
        }

        let violationOffset = lastPosition + commaIndex
        return (violationOffset, .extraTrailingCommaReason)
    }

    private func violations(file: SwiftLintFile, byteOffset: ByteCount, reason: String) -> [StyleViolation] {
        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: byteOffset),
                           reason: reason)
        ]
    }

    private func trailingCommaIndex(contents: String, file: SwiftLintFile, offset: ByteCount) -> ByteCount? {
        // skip commas in comments
        return Self.commaRegex
            .matches(in: contents, options: [], range: contents.fullNSRange)
            .map { $0.range }
            .last { nsRange in
                let offsetCharacter = file.stringView.location(fromByteOffset: offset)
                let offsetNSRange = NSRange(location: nsRange.location + offsetCharacter, length: nsRange.length)
                let byteRange = file.stringView.NSRangeToByteRange(offsetNSRange)!
                let kinds = file.syntaxMap.kinds(inByteRange: byteRange)
                return SyntaxKind.commentKinds.isDisjoint(with: kinds)
            }
            .flatMap(contents.NSRangeToByteRange)?
            .location
    }
}

private extension String {
    func NSRangeToByteRange(_ nsRange: NSRange) -> ByteRange? {
        let utf16View = utf16
        let utf8View = utf8

        let startUTF16Index = utf16View.index(utf16View.startIndex, offsetBy: nsRange.location)
        let endUTF16Index = utf16View.index(startUTF16Index, offsetBy: nsRange.length)

        guard let startUTF8Index = startUTF16Index.samePosition(in: utf8View),
            let endUTF8Index = endUTF16Index.samePosition(in: utf8View)
        else {
            return nil
        }

        let byteOffset = utf8View.distance(from: utf8View.startIndex, to: startUTF8Index)
        let length = utf8View.distance(from: startUTF8Index, to: endUTF8Index)
        return ByteRange(location: ByteCount(byteOffset), length: ByteCount(length))
    }
}
