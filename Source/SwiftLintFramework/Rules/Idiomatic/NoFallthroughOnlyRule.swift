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
        nonTriggeringExamples: [
            """
            switch myvar {
            case 1:
              var a = 1
              fallthrough
            case 2:
              var a = 2
            }
            """,
            """
            switch myvar {
            case "a":
              var one = 1
              var two = 2
              fallthrough
            case "b": /* comment */
              var three = 3
            }
            """,
            """
            switch myvar {
            case 1:
              let one = 1
            case 2:
              // comment
              var two = 2
            }
            """,
            """
            switch myvar {
            case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
              var three = 3
              fallthrough
            default:
              var three = 4
            }
            """,
            """
            switch myvar {
            case .alpha:
              var one = 1
            case .beta:
              var three = 3
              fallthrough
            default:
                var four = 4
            }
            """,
            """
            let aPoint = (1, -1)
            switch aPoint {
            case let (x, y) where x == y:
              let A = "A"
            case let (x, y) where x == -y:
              let B = "B"
              fallthrough
            default:
              let C = "C"
            }
            """,
            """
            switch myvar {
            case MyFun(with: { $1 }):
              let one = 1
              fallthrough
            case "abc":
              let two = 2
            }
            """
        ],
        triggeringExamples: [
            """
            switch myvar {
            case 1:
              ↓fallthrough
            case 2:
              var a = 1
            }
            """,
            """
            switch myvar {
            case 1:
              var a = 2
            case 2:
              ↓fallthrough
            case 3:
              var a = 3
            }
            """,
            """
            switch myvar {
            case 1: // comment
              ↓fallthrough
            }
            """,
            """
            switch myvar {
            case 1: /* multi
              line
              comment */
              ↓fallthrough
            case 2:
              var a = 2
            }
            """,
            """
            switch myvar {
            case MyFunc(x: [1, 2, YourFunc(a: 23)], y: 2):
              ↓fallthrough
            default:
              var three = 4
            }
            """,
            """
            switch myvar {
            case .alpha:
              var one = 1
            case .beta:
              ↓fallthrough
            case .gamma:
              var three = 3
            default:
              var four = 4
            }
            """,
            """
            let aPoint = (1, -1)
            switch aPoint {
            case let (x, y) where x == y:
              let A = "A"
            case let (x, y) where x == -y:
              ↓fallthrough
            default:
              let B = "B"
            }
            """,
            """
            switch myvar {
            case MyFun(with: { $1 }):
              ↓fallthrough
            case "abc":
              let two = 2
            }
            """
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
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
        if nsstring.substring(with: nsRange) == "fallthrough" && nonCommentCaseBody[0].1 == [.keyword] {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, characterOffset: nsRange.location))]
        }

        return []
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
