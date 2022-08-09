import Foundation
import SourceKittenFramework

public struct OptionalEnumCaseMatchingRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "optional_enum_case_matching",
        name: "Optional Enum Case Match",
        description: "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above.",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .baz): break
             default: break
            }
            """),
            Example("""
            switch (x, y) {
            case (.c, _?):
                break
            case (.c, nil):
                break
            case (_, _):
                break
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """)
        ],
        corrections: [
            Example("""
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case Foo.bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar, .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar where x > 1: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """): Example("""
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .bar): break
             default: break
            }
            """)
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - SubstitutionCorrectableASTRule

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile,
                                kind: StatementKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard kind == .case else {
            return []
        }

        let contents = file.stringView
        return dictionary.elements
            .filter { $0.kind == "source.lang.swift.structure.elem.pattern" }
            .flatMap { dictionary -> [NSRange] in
                guard let byteRange = dictionary.byteRange else {
                    return []
                }

                let pattern = contents.substringWithByteRange(byteRange)
                let tupleCommaByteOffsets = pattern?.tupleCommaByteOffsets ?? []

                let tokensToCheck = (tupleCommaByteOffsets + [byteRange.length]).compactMap { length in
                    return file.syntaxMap
                        .tokens(inByteRange: ByteRange(location: byteRange.location, length: length))
                        .prefix { $0.kind != .keyword || file.isTokenUnderscoreKeyword($0) }
                        .last
                }

                return tokensToCheck.compactMap { tokenToCheck in
                    guard !file.isTokenUnderscoreKeyword(tokenToCheck) else {
                        return nil
                    }
                    let questionMarkByteRange = ByteRange(location: tokenToCheck.range.upperBound, length: 1)
                    guard contents.substringWithByteRange(questionMarkByteRange) == "?" else {
                        return nil
                    }
                    return contents.byteRangeToNSRange(questionMarkByteRange)
                }
            }
    }
}

private extension String {
    func ranges(of substring: String) -> [Range<Index>] {
        var ranges = [Range<Index>]()
        while let range = range(of: substring, range: (ranges.last?.upperBound ?? startIndex)..<endIndex) {
            ranges.append(range)
        }
        return ranges
    }

    var isTuple: Bool {
        return first == "(" && last == ")" && contains(",")
    }

    var tupleCommaByteOffsets: [ByteCount] {
        guard isTuple else {
            return []
        }

        let stringView = StringView(self)
        return ranges(of: ",").map { range in
            return stringView.byteOffset(fromLocation: distance(from: startIndex, to: range.lowerBound))
        }
    }
}

private extension SwiftLintFile {
    func isTokenUnderscoreKeyword(_ token: SwiftLintSyntaxToken) -> Bool {
        return token.kind == .keyword &&
            token.length == 1 &&
            contents(for: token) == "_"
    }
}
