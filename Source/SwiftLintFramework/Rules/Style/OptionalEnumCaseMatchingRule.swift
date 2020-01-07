import Foundation
import SourceKittenFramework

public struct OptionalEnumCaseMatchingRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                            AutomaticTestableRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "optional_enum_case_matching",
        name: "Optional Enum Case Match",
        description: "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above. ",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            """
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .baz): break
             default: break
            }
            """
        ],
        triggeringExamples: [
            """
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """
        ],
        corrections: [
            """
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case Foo.bar: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """: """
            switch foo {
             case .bar, .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """: """
            switch foo {
             case .bar where x > 1: break
             case .baz: break
             default: break
            }
            """,
            """
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """: """
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .bar): break
             default: break
            }
            """
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
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
        guard SwiftVersion.current >= type(of: self).description.minSwiftVersion, kind == .case else {
            return []
        }

        let contents = file.stringView
        return dictionary.elements
            .filter { $0.kind == "source.lang.swift.structure.elem.pattern" }
            .flatMap { dictionary -> [NSRange] in
                guard let offset = dictionary.offset, let length = dictionary.length else {
                    return []
                }

                let pattern = contents.substringWithByteRange(start: offset, length: length)
                let tupleCommaByteOffsets = pattern?.tupleCommaByteOffsets ?? []

                let tokensToCheck = (tupleCommaByteOffsets + [length]).compactMap { length in
                    return file.syntaxMap
                        .tokens(inByteRange: NSRange(location: offset, length: length))
                        .prefix { $0.kind != .keyword || file.isTokenUnderscoreKeyword($0) }
                        .last
                }

                return tokensToCheck.compactMap { tokenToCheck in
                    let questionMarkByteOffset = tokenToCheck.length + tokenToCheck.offset
                    guard contents.substringWithByteRange(start: questionMarkByteOffset, length: 1) == "?" else {
                        return nil
                    }
                    return contents.byteRangeToNSRange(start: questionMarkByteOffset, length: 1)
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

    var tupleCommaByteOffsets: [Int] {
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
