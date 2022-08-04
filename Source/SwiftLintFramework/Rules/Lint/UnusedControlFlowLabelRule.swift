import Foundation
import SourceKittenFramework

public struct UnusedControlFlowLabelRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_control_flow_label",
        name: "Unused Control Flow Label",
        description: "Unused control flow label should be removed.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("loop: while true { break loop }"),
            Example("loop: while true { continue loop }"),
            Example("loop:\n    while true { break loop }"),
            Example("while true { break }"),
            Example("loop: for x in array { break loop }"),
            Example("""
            label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break label
            }
            """),
            Example("""
            loop: repeat {
                if x == 10 {
                    break loop
                }
            } while true
            """)
        ],
        triggeringExamples: [
            Example("↓loop: while true { break }"),
            Example("↓loop: while true { break loop1 }"),
            Example("↓loop: while true { break outerLoop }"),
            Example("↓loop: for x in array { break }"),
            Example("""
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """),
            Example("""
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """)
        ],
        corrections: [
            Example("↓loop: while true { break }"): Example("while true { break }"),
            Example("↓loop: while true { break loop1 }"): Example("while true { break loop1 }"),
            Example("↓loop: while true { break outerLoop }"): Example("while true { break outerLoop }"),
            Example("↓loop: for x in array { break }"): Example("for x in array { break }"),
            Example("""
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """): Example("""
                switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """),
            Example("""
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """): Example("""
                repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """)
        ]
    )

    private static let kinds: Set<StatementKind> = [.if, .for, .forEach, .while, .repeatWhile, .switch]

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return self.violationRanges(in: file, kind: kind, dictionary: dictionary).map { range in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        var rangeToRemove = violationRange
        let contentsNSString = file.stringView
        if let byteRange = contentsNSString.NSRangeToByteRange(start: violationRange.location,
                                                               length: violationRange.length),
            let nextToken = file.syntaxMap.tokens.first(where: { $0.offset > byteRange.location }) {
            let nextTokenLocation = contentsNSString.location(fromByteOffset: nextToken.offset)
            rangeToRemove.length = nextTokenLocation - violationRange.location
        }

        return (rangeToRemove, "")
    }

    public func violationRanges(in file: SwiftLintFile, kind: StatementKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard Self.kinds.contains(kind),
            let byteRange = dictionary.byteRange,
            case let tokens = file.syntaxMap.tokens(inByteRange: byteRange),
            let firstToken = tokens.first,
            firstToken.kind == .identifier,
            let tokenContent = file.contents(for: firstToken),
            case let contents = file.stringView,
            let range = contents.byteRangeToNSRange(byteRange),
            case let pattern = "(?:break|continue)\\s+\(tokenContent)\\b",
            file.match(pattern: pattern, with: [.keyword, .identifier], range: range).isEmpty,
            let violationRange = contents.byteRangeToNSRange(firstToken.range)
        else {
            return []
        }

        return [violationRange]
    }
}
