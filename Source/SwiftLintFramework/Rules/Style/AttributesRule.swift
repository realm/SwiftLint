import Foundation
import SourceKittenFramework

private enum AttributesRuleError: Error {
    case unexpectedBlankLine
    case moreThanOneAttributeInSameLine
}

public struct AttributesRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = AttributesConfiguration()

    private static let parametersPattern = "^\\s*\\(.+\\)"
    private static let regularExpression = regex(parametersPattern, options: [])

    public init() {}

    public static let description = RuleDescription(
        identifier: "attributes",
        name: "Attributes",
        description: "Attributes should be on their own lines in functions and types, " +
                     "but on the same line as variables and imports.",
        kind: .style,
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples,
        triggeringExamples: AttributesRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return validateTestableImport(file: file) +
            validate(file: file, dictionary: file.structureDictionary)
    }

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let attributeShouldBeOnSameLine: Bool?
        if SwiftDeclarationKind.variableKinds.contains(kind) {
            attributeShouldBeOnSameLine = true
        } else if SwiftDeclarationKind.typeKinds.contains(kind) {
            attributeShouldBeOnSameLine = false
        } else if SwiftDeclarationKind.functionKinds.contains(kind) {
            attributeShouldBeOnSameLine = false
        } else {
            attributeShouldBeOnSameLine = nil
        }

        if let attributeShouldBeOnSameLine = attributeShouldBeOnSameLine {
            return validateKind(file: file,
                                attributeShouldBeOnSameLine: attributeShouldBeOnSameLine,
                                dictionary: dictionary)
        }

        return []
    }

    private func validateTestableImport(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "@testable[\n]+\\s*import"
        return file.match(pattern: pattern).compactMap { range, kinds -> StyleViolation? in
            guard kinds == [.attributeBuiltin, .keyword] else {
                return nil
            }

            let contents = file.stringView
            let match = contents.substring(with: range)
            let idx = match.lastIndex(of: "import") ?? 0
            let location = idx + range.location

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: location))
        }
    }

    private func validateKind(file: SwiftLintFile,
                              attributeShouldBeOnSameLine: Bool,
                              dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let attributes = parseAttributes(dictionary: dictionary)

        guard attributes.isNotEmpty,
            let offset = dictionary.offset,
            let (line, _) = file.stringView.lineAndCharacter(forByteOffset: offset) else {
            return []
        }

        guard isViolation(lineNumber: line, file: file,
                          attributeShouldBeOnSameLine: attributeShouldBeOnSameLine) else {
            return []
        }

        // Violation found!
        return violation(dictionary: dictionary, file: file)
    }

    private func isViolation(lineNumber: Int, file: SwiftLintFile,
                             attributeShouldBeOnSameLine: Bool) -> Bool {
        let line = file.lines[lineNumber - 1]

        let tokens = file.syntaxMap.tokens(inByteRange: line.byteRange)
        let attributesTokensWithRanges = tokens.compactMap { attributeName(token: $0, file: file) }

        let attributesTokens = Set(
            attributesTokensWithRanges.map { tokenString, _ in
                // Some attributes are parameterized, such as `@objc(name)`, so discard anything from an opening
                // parenthesis onward.
                String(tokenString.prefix(while: { $0 != "(" }))
            }
        )

        do {
            let previousAttributesWithParameters = try attributesFromPreviousLines(lineNumber: lineNumber - 1,
                                                                                   file: file)
            let previousAttributes = Set(previousAttributesWithParameters.map { $0.0 })

            if previousAttributes.isEmpty && attributesTokens.isEmpty {
                return false
            }

            let alwaysOnSameLineAttributes = configuration.alwaysOnSameLine
            let alwaysOnNewLineAttributes =
                createAlwaysOnNewLineAttributes(previousAttributes: previousAttributesWithParameters,
                                                attributesTokens: attributesTokensWithRanges,
                                                line: line, file: file)

            guard attributesTokens.isDisjoint(with: alwaysOnNewLineAttributes) &&
                previousAttributes.isDisjoint(with: alwaysOnSameLineAttributes) else {
                return true
            }

            // ignore attributes that are explicitly allowed
            let attributesAfterAllowed: Set<String>
            let newLineExceptions = previousAttributes.intersection(alwaysOnNewLineAttributes)
            let sameLineExceptions = attributesTokens.intersection(alwaysOnSameLineAttributes)

            if attributeShouldBeOnSameLine {
                attributesAfterAllowed = attributesTokens
                    .union(newLineExceptions)
                    .union(sameLineExceptions)
            } else {
                attributesAfterAllowed = attributesTokens
                    .subtracting(newLineExceptions)
                    .subtracting(sameLineExceptions)
            }

            return attributesAfterAllowed.isEmpty == attributeShouldBeOnSameLine
        } catch {
            return true
        }
    }

    private func createAlwaysOnNewLineAttributes(previousAttributes: [(String, Bool)],
                                                 attributesTokens: [(String, ByteRange)],
                                                 line: Line, file: SwiftLintFile) -> Set<String> {
        let attributesTokensWithParameters: [(String, Bool)] = attributesTokens.map {
            let hasParameter = attributeContainsParameter(attributeRange: $1,
                                                          line: line, file: file)
            return ($0, hasParameter)
        }
        let allAttributes = previousAttributes + attributesTokensWithParameters

        return Set(allAttributes.compactMap { token, hasParameter -> String? in
            // an attribute should be on a new line if one of these is true:
            // 1. it's a parameterized attribute
            //      a. the parameter is on the token (i.e. warn_unused_result)
            //      b. the parameter was parsed in the `hasParameter` variable (most attributes)
            // 2. it's an allowed attribute, according to the current configuration
            let isParameterized = hasParameter || token.bridge().contains("(")
            if isParameterized || configuration.alwaysOnNewLine.contains(token) {
                return token
            }

            return nil
        })
    }

    private func violation(dictionary: SourceKittenDictionary,
                           file: SwiftLintFile) -> [StyleViolation] {
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: location)
        ]
    }

    // returns an array with the token itself (i.e. "@objc") and whether it's parameterized
    // note: the parameter is not contained in the token
    private func attributesFromPreviousLines(lineNumber: Int,
                                             file: SwiftLintFile) throws -> [(String, Bool)] {
        var currentLine = lineNumber - 1
        var allTokens = [(String, Bool)]()
        var foundEmptyLine = false

        while currentLine >= 0 {
            defer {
                currentLine -= 1
            }

            let line = file.lines[currentLine]
            let tokens = file.syntaxMap.tokens(inByteRange: line.byteRange)

            if tokens.isEmpty {
                foundEmptyLine = true
                continue
            }

            // check if it's a line with other declaration which could have its own attributes
            let nonAttributeTokens = tokens.filter { token in
                guard token.kind == .keyword,
                    let keyword = file.contents(for: token) else {
                    return false
                }

                let keywords: Set = ["func", "var", "let", "class", "struct",
                                     "enum", "protocol", "import"]
                return keywords.contains(keyword)
            }

            guard nonAttributeTokens.isEmpty else {
                break
            }

            let attributesTokens = tokens.compactMap { attributeName(token: $0, file: file) }
            guard let firstTokenRange = attributesTokens.first?.1 else {
                // found a line that does not contain an attribute token - we can stop looking
                break
            }

            if attributesTokens.count > 1 {
                // we don't allow multiple attributes in the same line if it's a previous line
                throw AttributesRuleError.moreThanOneAttributeInSameLine
            }

            if foundEmptyLine {
                // we don't allow attributes with empty lines between them
                throw AttributesRuleError.unexpectedBlankLine
            }

            let hasParameter = attributeContainsParameter(attributeRange: firstTokenRange,
                                                          line: line, file: file)

            allTokens.insert(contentsOf: attributesTokens.map { ($0.0, hasParameter) }, at: 0)
        }

        return allTokens
    }

    private func attributeContainsParameter(attributeRange: ByteRange,
                                            line: Line, file: SwiftLintFile) -> Bool {
        let restOfLineOffset = attributeRange.upperBound
        let restOfLineLength = line.byteRange.upperBound - restOfLineOffset
        if restOfLineLength < 0 {
            // If attribute spans multiple lines, it must have a parameter.
            return true
        }

        let regex = Self.regularExpression
        let contents = file.stringView

        // check if after the token is a `(` with only spaces allowed between the token and `(`
        let restOfLineByteRange = ByteRange(location: restOfLineOffset, length: restOfLineLength)
        guard let restOfLine = contents.substringWithByteRange(restOfLineByteRange),
            case let range = restOfLine.fullNSRange,
            regex.firstMatch(in: restOfLine, options: [], range: range) != nil else {
            return false
        }

        return true
    }

    private func attributeName(token: SwiftLintSyntaxToken, file: SwiftLintFile) -> (String, ByteRange)? {
        guard token.kind == .attributeBuiltin else {
            return nil
        }

        let maybeName = file.contents(for: token)
        if let name = maybeName, isAttribute(name) {
            return (name, token.range)
        }

        return nil
    }

    private func isAttribute(_ name: String) -> Bool {
        if name == "@escaping" || name == "@autoclosure" {
            return false
        }

        // all attributes *should* start with @
        if name.hasPrefix("@") {
            return true
        }

        // for some reason, `@` is not included if @warn_unused_result has parameters
        if name.hasPrefix("warn_unused_result(") {
            return true
        }

        return false
    }

    private func parseAttributes(dictionary: SourceKittenDictionary) -> [SwiftDeclarationAttributeKind] {
        let attributes = dictionary.enclosedSwiftAttributes
        return attributes.filter { !kIgnoredAttributes.contains($0) }
    }
}

private let kIgnoredAttributes: Set<SwiftDeclarationAttributeKind> = [
    .dynamic,
    .fileprivate,
    .final,
    .infix,
    .internal,
    .lazy,
    .mutating,
    .nonmutating,
    .open,
    .optional,
    .override,
    .postfix,
    .prefix,
    .private,
    .public,
    .required,
    .rethrows,
    .setterFilePrivate,
    .setterInternal,
    .setterOpen,
    .setterPrivate,
    .setterPublic,
    .weak
]
