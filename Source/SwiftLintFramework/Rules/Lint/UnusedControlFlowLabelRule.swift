import Foundation
import SourceKittenFramework

public struct UnusedControlFlowLabelRule: SubstitutionCorrectableASTRule, ConfigurationProviderRule,
                                          AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_control_flow_label",
        name: "Unused Control Flow Label",
        description: "Unused control flow label should be removed.",
        kind: .lint,
        nonTriggeringExamples: [
            "loop: while true { break loop }",
            "loop: while true { continue loop }",
            "loop:\n    while true { break loop }",
            "while true { break }",
            "loop: for x in array { break loop }",
            """
            label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break label
            }
            """,
            """
            loop: repeat {
                if x == 10 {
                    break loop
                }
            } while true
            """
        ],
        triggeringExamples: [
            "↓loop: while true { break }",
            "↓loop: while true { break loop1 }",
            "↓loop: while true { break outerLoop }",
            "↓loop: for x in array { break }",
            """
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """,
            """
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """
        ],
        corrections: [
            "↓loop: while true { break }": "while true { break }",
            "↓loop: while true { break loop1 }": "while true { break loop1 }",
            "↓loop: while true { break outerLoop }": "while true { break outerLoop }",
            "↓loop: for x in array { break }": "for x in array { break }",
            """
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """: """
                switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """,
            """
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """: """
                repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """
        ]
    )

    private static let kinds: Set<StatementKind> = [.if, .for, .forEach, .while, .repeatWhile, .switch]

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return self.violationRanges(in: file, kind: kind, dictionary: dictionary).map { range in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        var rangeToRemove = violationRange
        let contentsNSString = file.linesContainer
        if let byteRange = contentsNSString.NSRangeToByteRange(start: violationRange.location,
                                                               length: violationRange.length),
            let nextToken = file.syntaxMap.tokens.first(where: { $0.offset > byteRange.location }),
            let nextTokenLocation = contentsNSString.byteRangeToNSRange(start: nextToken.offset, length: 0) {
            rangeToRemove.length = nextTokenLocation.location - violationRange.location
        }

        return (rangeToRemove, "")
    }

    public func violationRanges(in file: SwiftLintFile, kind: StatementKind,
                                dictionary: SourceKittenDictionary) -> [NSRange] {
        guard type(of: self).kinds.contains(kind),
            let offset = dictionary.offset, let length = dictionary.length,
            case let byteRange = NSRange(location: offset, length: length),
            case let tokens = file.syntaxMap.tokens(inByteRange: byteRange),
            let firstToken = tokens.first,
            firstToken.kind == .identifier,
            let tokenContent = file.contents(for: firstToken),
            case let contents = file.linesContainer,
            let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        let pattern = "(?:break|continue)\\s+\(tokenContent)\\b"
        guard file.match(pattern: pattern, with: [.keyword, .identifier], range: range).isEmpty,
            let violationRange = contents.byteRangeToNSRange(start: firstToken.offset,
                                                             length: firstToken.length) else {
                return []
        }

        return [violationRange]
    }
}
