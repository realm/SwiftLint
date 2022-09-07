import Foundation
import SourceKittenFramework

// swiftlint:disable type_body_length

public struct TypesafeArrayInitRule: AnalyzerRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "typesafe_array_init",
        name: "Type-safe Array Init",
        description: "Prefer using `Array(seq)` over `seq.map { $0 }` to convert a sequence into an Array.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                enum MyError: Error {}
                let myResult: Result<String, MyError> = .success("")
                let result: Result<Any, MyError> = myResult.map { $0 }
            """),
            Example("""
                struct IntArray {
                    let elements = [1, 2, 3]
                    func map<T>(_ transformer: (Int) throws -> T) rethrows -> [T] {
                        try elements.map(transformer)
                    }
                }
                let ints = IntArray()
                let intsCopy = ints.map { $0 }
            """)
        ],
        triggeringExamples: [
            Example("""
                func f<Seq: Sequence>(s: Seq) -> [Seq.Element] {
                    ↓s.map({ $0 })
                }
            """),
            Example("""
                func f(array: [Int]) -> [Int] {
                    ↓array.map { $0 }
                }
            """),
            Example("""
                let myInts = ↓[1, 2, 3].map { return $0 }
            """),
            Example("""
                struct Generator: Sequence, IteratorProtocol {
                    func next() -> Int? { nil }
                }
                let array = ↓Generator().map { i in i }
            """)
        ],
        requiresFileOnDisk: true
    )

    private static let mapTypePattern = regex("""
            \\Q<Self, T where Self : \\E(?:Sequence|Collection)> \
            \\Q(Self) -> ((Self.Element) throws -> T) throws -> [T]\\E
            """)

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        guard let filePath = file.path else {
            return []
        }
        guard compilerArguments.isNotEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule without any compiler arguments.
                """)
            return []
        }
        let index = buildIndex(for: filePath, using: compilerArguments)
        return index.traverseEntitiesDepthFirst { substructure -> [StyleViolation]? in
            guard substructure.kind == "source.lang.swift.ref.function.method.instance",
                  let line = substructure.line, let column = substructure.column,
                  let offset = file.stringView.byteOffset(forLine: line, bytePosition: column) else {
                return nil
            }
            let cursorInfoRequest = Request.cursorInfo(file: filePath, offset: offset, arguments: compilerArguments)
            guard let cursorInfo = try? cursorInfoRequest.sendIfNotDisabled(),
                  let isSystem = cursorInfo["key.is_system"], isSystem.isEqualTo(true),
                  let name = cursorInfo["key.name"], name.isEqualTo("map(_:)"),
                  let typeName = cursorInfo["key.typename"] as? String,
                  Self.mapTypePattern.numberOfMatches(in: typeName, range: typeName.fullNSRange) == 1,
                  let dict = pickSubstructure(from: file.structureDictionary, at: offset) else {
                return nil
            }
            return validate(
                file: file,
                dictionary: dict,
                description: Self.description,
                severity: configuration.severity
            )
        }.flatMap { $0 }
    }

    private func buildIndex(for filePath: String, using compilerArguments: [String]) -> SourceKittenDictionary {
        do {
            return SourceKittenDictionary(
                try Request.index(file: filePath, arguments: compilerArguments).sendIfNotDisabled()
            )
        } catch {
            queuedPrintError("""
                Indexing of file '\(filePath)' in the context of the \(Self.description.identifier) rule failed.
                """)
        }
        return SourceKittenDictionary([:])
    }

    private func pickSubstructure(from: SourceKittenDictionary, at mapOffset: ByteCount) -> SourceKittenDictionary? {
        let substructures = from.traverseBreadthFirst { substructure -> [SourceKittenDictionary]? in
            guard substructure.expressionKind == .call,
                  let name = substructure.name, name.hasSuffix(".map"),
                  let nameOffset = substructure.nameOffset,
                  let nameLength = substructure.nameLength,
                  mapOffset + ByteCount("map".count) == nameOffset + nameLength else {
                return nil
            }
            return [substructure]
        }
        return substructures.count == 1 ? substructures.first : nil
    }

    private func validate(file: SwiftLintFile, dictionary: SourceKittenDictionary, description: RuleDescription,
                          severity: ViolationSeverity) -> [StyleViolation] {
        guard let name = dictionary.name, name.hasSuffix(".map"),
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
            StyleViolation(ruleDescription: description,
                           severity: severity,
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

            if processedSubstring.isNotEmpty {
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
