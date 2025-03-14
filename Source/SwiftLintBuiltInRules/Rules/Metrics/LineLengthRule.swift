import Foundation
import SwiftSyntax
import SwiftLintCore

@SwiftSyntaxRule
struct LineLengthRule: Rule {
    var configuration = LineLengthConfiguration()

    static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("This is a short line."),
            Example(repeatElement("This is a very long line.", count: 2).joined(separator: "\n")),
            Example("//This is a very very very very very very very very very very very very long comment"),
            Example("/* This is a very very very very very very very very very very very very long comment */"),
            Example("let foo = \"This is a very very very very very very very very very very very very long string\""),
            Example("""
            <script>
                // This is a very very very very very very very very very very very very long comment
            </script>
            """),
            Example("let foo = \"This is a very very very very very very very very very very very very long string\"\n" +
                   "let bar = \"This is a very very very very very very very very very very very very long string\"")
        ],
        triggeringExamples: [
            Example("↓This is a very very very very very very very very very very very very very very long line."),
            Example("//↓This is a very very very very very very very very very very very very very very long comment"),
            Example("let foo = \"↓This is a very very very very very very very very very very very very very very long string\""),
            Example("""
            <script>
                // ↓This is a very very very very very very very very very very very very very very long comment
            </script>
            """)
        ]
    )
}

private extension LineLengthRule {
    final class Visitor: ViolationsSyntaxVisitor<LineLengthConfiguration> {
        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            let lines = node.description.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                let lineLength = line.lengthWithoutIgnoredContent
                for param in configuration.params where lineLength > param.value {
                    violations.append(
                        ReasonedRuleViolation(
                            position: AbsolutePosition(utf8Offset: 0),
                            reason: "Line should be \(param.value) characters or less; currently it has \(lineLength) characters"
                        )
                    )
                }
            }
            return .skipChildren
        }
    }
}

private extension String {
    var lengthWithoutIgnoredContent: Int {
        #if os(Windows)
        return self.count
        #else
        let types = NSTextCheckingResult.CheckingType.link.rawValue
        guard let urlDetector = try? NSDataDetector(types: types) else {
            return self.count
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return urlDetector.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "").count
        #endif
    }
}
