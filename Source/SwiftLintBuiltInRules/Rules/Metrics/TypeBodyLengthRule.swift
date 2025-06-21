import SwiftSyntax

private func wrapExample(
    prefix: String = "",
    _ type: String,
    _ template: String,
    _ count: Int,
    _ add: String = "",
    file: StaticString = #filePath,
    line: UInt = #line) -> Example {
    Example("\(prefix)\(type) Abc {\n" +
                   repeatElement(template, count: count).joined() + "\(add)}\n", file: file, line: line)
}

@SwiftSyntaxRule
struct TypeBodyLengthRule: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 250, error: 350)

    static let description = RuleDescription(
        identifier: "type_body_length",
        name: "Type Body Length",
        description: "Type bodies should not span too many lines",
        kind: .metrics,
        nonTriggeringExamples: ["class", "struct", "enum", "actor"].flatMap({ type in
            [
                wrapExample(type, "let abc = 0\n", 249),
                wrapExample(type, "\n", 251),
                wrapExample(type, "// this is a comment\n", 251),
                wrapExample(type, "let abc = 0\n", 249, "\n/* this is\na multiline comment\n*/"),
            ]
        }),
        triggeringExamples: ["class", "struct", "enum", "actor"].map({ type in
             wrapExample(prefix: "↓", type, "let abc = 0\n", 251)
        })
    )
}

private extension TypeBodyLengthRule {
    final class Visitor: BodyLengthVisitor<TypeBodyLengthRule> {
        override func visitPost(_ node: ActorDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            collectViolation(node)
        }

        override func visitPost(_ node: StructDeclSyntax) {
            collectViolation(node)
        }

        private func collectViolation(_ node: some DeclGroupSyntax) {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.introducer,
                objectName: node.introducer.text.capitalized
            )
        }
    }
}
