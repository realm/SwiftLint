//
//  AttributesRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

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
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples,
        triggeringExamples: AttributesRuleExamples.triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        return validateTestableImport(file: file) +
            validate(file: file, dictionary: file.structure.dictionary)
    }

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        let attributeShouldBeOnSameLine: Bool?
        if SwiftDeclarationKind.variableKinds().contains(kind) {
            attributeShouldBeOnSameLine = true
        } else if SwiftDeclarationKind.typeKinds().contains(kind) {
            attributeShouldBeOnSameLine = false
        } else if SwiftDeclarationKind.functionKinds().contains(kind) {
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

    private func validateTestableImport(file: File) -> [StyleViolation] {
        let pattern = "@testable[\n]+\\s*import"
        return file.match(pattern: pattern).flatMap { range, kinds -> StyleViolation? in
            guard kinds == [.attributeBuiltin, .keyword] else {
                return nil
            }

            let contents = file.contents.bridge()
            let match = contents.substring(with: range)
            let idx = match.lastIndex(of: "import") ?? 0
            let location = idx + range.location

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: location))
        }
    }

    private func validateKind(file: File,
                              attributeShouldBeOnSameLine: Bool,
                              dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let attributes = parseAttributes(dictionary: dictionary)

        guard !attributes.isEmpty,
            let offset = dictionary.offset,
            let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: offset) else {
            return []
        }

        guard isViolation(lineNumber: line, file: file,
                          attributeShouldBeOnSameLine: attributeShouldBeOnSameLine) else {
            return []
        }

        // Violation found!
        return violation(dictionary: dictionary, file: file)
    }

    private func isViolation(lineNumber: Int, file: File,
                             attributeShouldBeOnSameLine: Bool) -> Bool {
        let line = file.lines[lineNumber - 1]

        let tokens = file.syntaxMap.tokens(inByteRange: line.byteRange)
        let attributesTokensWithRanges = tokens.flatMap { attributeName(token: $0, file: file) }

        let attributesTokens = Set(attributesTokensWithRanges.map { $0.0 })

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

            guard attributesTokens.intersection(alwaysOnNewLineAttributes).isEmpty &&
                previousAttributes.intersection(alwaysOnSameLineAttributes).isEmpty else {
                return true
            }

            // ignore whitelisted attributes
            let attributesAfterWhitelist: Set<String>
            let newLineExceptions = previousAttributes.intersection(alwaysOnNewLineAttributes)
            let sameLineExceptions = attributesTokens.intersection(alwaysOnSameLineAttributes)

            if attributeShouldBeOnSameLine {
                attributesAfterWhitelist = attributesTokens
                    .union(newLineExceptions).union(sameLineExceptions)
            } else {
                attributesAfterWhitelist = attributesTokens
                    .subtracting(newLineExceptions).subtracting(sameLineExceptions)
            }

            return attributesAfterWhitelist.isEmpty == attributeShouldBeOnSameLine
        } catch {
            return true
        }
    }

    private func createAlwaysOnNewLineAttributes(previousAttributes: [(String, Bool)],
                                                 attributesTokens: [(String, NSRange)],
                                                 line: Line, file: File) -> Set<String> {
        let attributesTokensWithParameters: [(String, Bool)] = attributesTokens.map {
            let hasParameter = attributeContainsParameter(attributeRange: $1,
                                                          line: line, file: file)
            return ($0, hasParameter)
        }
        let allAttributes = previousAttributes + attributesTokensWithParameters

        return Set(allAttributes.flatMap { (token, hasParameter) -> String? in
            // an attribute should be on a new line if one of these is true:
            // 1. it's a parameterized attribute
            //      a. the parameter is on the token (i.e. warn_unused_result)
            //      b. the parameter was parsed in the `hasParameter` variable (most attributes)
            // 2. it's a whitelisted attribute, according to the current configuration
            let isParameterized = hasParameter || token.bridge().contains("(")
            if isParameterized || configuration.alwaysOnNewLine.contains(token) {
                return token
            }

            return nil
        })
    }

    private func violation(dictionary: [String: SourceKitRepresentable],
                           file: File) -> [StyleViolation] {
        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: location)
        ]
    }

    // returns an array with the token itself (i.e. "@objc") and whether it's parameterized
    // note: the parameter is not contained in the token
    private func attributesFromPreviousLines(lineNumber: Int,
                                             file: File) throws -> [(String, Bool)] {
        var currentLine = lineNumber - 1
        var allTokens = [(String, Bool)]()
        var foundEmptyLine = false
        let contents = file.contents.bridge()

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
                guard SyntaxKind(rawValue: token.type) == .keyword,
                    let keyword = contents.substringWithByteRange(start: token.offset,
                                                                  length: token.length) else {
                    return false
                }

                return ["func", "var", "let"].contains(keyword)
            }

            guard nonAttributeTokens.isEmpty else {
                break
            }

            let attributesTokens = tokens.flatMap { attributeName(token: $0, file: file) }
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

    private func attributeContainsParameter(attributeRange: NSRange,
                                            line: Line, file: File) -> Bool {
        let restOfLineOffset = attributeRange.location + attributeRange.length
        let restOfLineLength = line.byteRange.location + line.byteRange.length - restOfLineOffset

        let regex = AttributesRule.regularExpression
        let contents = file.contents.bridge()

        // check if after the token is a `(` with only spaces allowed between the token and `(`
        guard let restOfLine = contents.substringWithByteRange(start: restOfLineOffset, length: restOfLineLength),
            case let range = NSRange(location: 0, length: restOfLine.bridge().length),
            regex.firstMatch(in: restOfLine, options: [], range: range) != nil else {

            return false
        }

        return true
    }

    private func attributeName(token: SyntaxToken, file: File) -> (String, NSRange)? {
        guard SyntaxKind(rawValue: token.type) == .attributeBuiltin else {
            return nil
        }

        let maybeName = file.contents.bridge().substringWithByteRange(start: token.offset,
                                                                      length: token.length)
        if let name = maybeName, isAttribute(name) {
            return (name, NSRange(location: token.offset, length: token.length))
        }

        return nil
    }

    private func isAttribute(_ name: String) -> Bool {
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

    private func parseAttributes(dictionary: [String: SourceKitRepresentable]) -> [String] {
        let attributes = dictionary.enclosedSwiftAttributes
        let blacklist: Set<String> = [
            "source.decl.attribute.__raw_doc_comment",
            "source.decl.attribute.mutating",
            "source.decl.attribute.nonmutating",
            "source.decl.attribute.lazy",
            "source.decl.attribute.dynamic",
            "source.decl.attribute.final",
            "source.decl.attribute.infix",
            "source.decl.attribute.optional",
            "source.decl.attribute.override",
            "source.decl.attribute.postfix",
            "source.decl.attribute.prefix",
            "source.decl.attribute.required",
            "source.decl.attribute.weak"
        ]
        return attributes.filter { !blacklist.contains($0) }
    }
}
