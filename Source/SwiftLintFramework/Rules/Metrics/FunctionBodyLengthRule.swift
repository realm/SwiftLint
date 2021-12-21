import SourceKittenFramework

public struct FunctionBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = FunctionBodyLengthConfiguration(warning: 40, error: 100, excluded: [])

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines.",
        kind: .metrics
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let input = RuleInput(file: file, kind: kind, dictionary: dictionary) else {
            return []
        }

        let functionNameWithoutAgruments = dictionary.name?.split(separator: "(").first
          .flatMap(String.init)?
          .trimmingCharacters(in: .whitespacesAndNewlines)

        for parameter in configuration.severityConfiguration.params {
            let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(
                input.startLine, input.endLine, parameter.value
            )
            guard exceeds else { continue }

            if let maybeExcludedFunction = functionNameWithoutAgruments,
                configuration.excluded.contains(maybeExcludedFunction) {
                return []
            } else {
                return [
                    StyleViolation(
                        ruleDescription: Self.description, severity: parameter.severity,
                        location: Location(file: file, byteOffset: input.offset),
                        reason: """
                        Function body should span \(configuration.severityConfiguration.warning) \
                        lines or less excluding comments and \
                        whitespace: currently spans \(lineCount) lines
                        """
                    )
                ]
            }
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
