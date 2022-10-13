import SourceKittenFramework

private func wrapExample(
    prefix: String = "",
    _ type: String,
    _ template: String,
    _ count: Int,
    _ add: String = "",
    file: StaticString = #file,
    line: UInt = #line) -> Example {
    return Example("\(prefix)\(type) Abc {\n" +
                   repeatElement(template, count: count).joined() + "\(add)}\n", file: file, line: line)
}

public struct TypeBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 250, error: 350)

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_body_length",
        name: "Type Body Length",
        description: "Type bodies should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap({ type in
            [
                wrapExample(type, "let abc = 0\n", 249),
                wrapExample(type, "\n", 251),
                wrapExample(type, "// this is a comment\n", 251),
                wrapExample(type, "let abc = 0\n", 249, "\n/* this is\na multiline comment\n*/\n")
            ]
        }),
        triggeringExamples: ["class", "struct", "enum"].map({ type in
             wrapExample(prefix: "↓", type, "let abc = 0\n", 251)
        })
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.typeKinds.contains(kind) else {
            return []
        }
        if let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength {
            let startLine = file.stringView.lineAndCharacter(forByteOffset: bodyOffset)
            let endLine = file.stringView
                .lineAndCharacter(forByteOffset: bodyOffset + bodyLength)

            if let leftBraceLine = startLine?.line, let rightBraceLine = endLine?.line {
                for parameter in configuration.params {
                    let result = BodyLineCounter.lineCountIgnoringCommentsAndWhitespace(
                        file: file, leftBraceLine: leftBraceLine, rightBraceLine: rightBraceLine, limit: parameter.value
                    )
                    let (exceeds, lineCount) = (result.exceeds, result.lineCount)
                    if exceeds {
                        let reason = "Type body should span \(configuration.warning) lines or less " +
                            "excluding comments and whitespace: currently spans \(lineCount) lines"
                        return [StyleViolation(ruleDescription: Self.description,
                                               severity: parameter.severity,
                                               location: Location(file: file, byteOffset: offset),
                                               reason: reason)]
                    }
                }
            }
        }
        return []
    }
}
