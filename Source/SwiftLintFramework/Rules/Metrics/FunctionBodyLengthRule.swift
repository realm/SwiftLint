import SourceKittenFramework

public struct FunctionBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 50, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines.",
        kind: .metrics
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let input = RuleInput(file: file, kind: kind, dictionary: dictionary) else {
            return []
        }

        for parameter in configuration.params {
            let result = BodyLineCounter.lineCountIgnoringCommentsAndWhitespace(
                file: file, leftBraceLine: input.startLine, rightBraceLine: input.endLine, limit: parameter.value
            )
            let (exceeds, lineCount) = (result.exceeds, result.lineCount)
            guard exceeds else { continue }
            return [
                StyleViolation(
                    ruleDescription: Self.description, severity: parameter.severity,
                    location: Location(file: file, byteOffset: input.offset),
                    reason: """
                        Function body should span \(configuration.warning) lines or less excluding comments and \
                        whitespace: currently spans \(lineCount) lines
                        """
                )
            ]
        }

        return []
    }
}

private struct RuleInput {
    let offset: ByteCount
    let startLine: Int
    let endLine: Int

    init?(file: SwiftLintFile, kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary) {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let contentsNSString = file.stringView,
            let startLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset)?.line,
            let endLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
        else {
            return nil
        }

        self.offset = offset
        self.startLine = startLine
        self.endLine = endLine
    }
}
