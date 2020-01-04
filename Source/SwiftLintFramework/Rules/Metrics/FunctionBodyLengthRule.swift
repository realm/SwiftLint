import SourceKittenFramework

public struct FunctionBodyLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 40, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Functions bodies should not span too many lines.",
        kind: .metrics
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let contentsNSString = file.stringView,
            let startLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset)?.line,
            let endLine = contentsNSString.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
        else {
            return []
        }
        for parameter in configuration.params {
            let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(
                startLine, endLine, parameter.value
            )
            guard exceeds else { continue }
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: parameter.severity,
                                   location: Location(file: file, byteOffset: offset),
                                   reason: "Function body should span \(configuration.warning) lines or less " +
                                           "excluding comments and whitespace: currently spans \(lineCount) " +
                                           "lines")]
        }
        return []
    }
}
