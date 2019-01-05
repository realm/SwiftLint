import Foundation
import SourceKittenFramework

public struct UnusedControlFlowLabelRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
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
        ]
    )

    private static let kinds: Set<StatementKind> = [.if, .for, .forEach, .while, .repeatWhile, .switch]

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard type(of: self).kinds.contains(kind),
            let offset = dictionary.offset, let length = dictionary.length,
            case let byteRange = NSRange(location: offset, length: length),
            case let tokens = file.syntaxMap.tokens(inByteRange: byteRange),
            let firstToken = tokens.first,
            SyntaxKind(rawValue: firstToken.type) == .identifier,
            case let contents = file.contents.bridge(),
            let tokenContent = contents.substring(with: firstToken),
            let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        let pattern = "(?:break|continue)\\s+\(tokenContent)\\b"
        guard file.match(pattern: pattern, with: [.keyword, .identifier], range: range).isEmpty else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: firstToken.offset))
        ]
    }
}

private extension NSString {
    func substring(with token: SyntaxToken) -> String? {
        return substringWithByteRange(start: token.offset, length: token.length)
    }
}
