//
//  AttributesRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/15/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum AttributesRuleError: ErrorType {
    case UnexpectedBlankLine
    case MoreThanOneAttributeInSameLine
}

public struct AttributesRule: ASTRule, ConfigurationProviderRule {
    public var configuration = AttributesConfiguration()

    private static let parametersPattern = "^\\s*\\(.+\\)"

    // swiftlint:disable:next force_try
    private static let regularExpression = try! NSRegularExpression(pattern: parametersPattern,
                                                                    options: [])

    public init() {}

    public static let description = RuleDescription(
        identifier: "attributes_rule",
        name: "Attributes",
        description: "Attributes should be on their own lines in functions and types, " +
                     "but on the same line as variables and imports.",
        nonTriggeringExamples: AttributesRuleExamples.nonTriggeringExamples(),
        triggeringExamples: AttributesRuleExamples.triggeringExamples()
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return validateTestableImport(file) +
            validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
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

        let violations: [StyleViolation]
        if let attributeShouldBeOnSameLine = attributeShouldBeOnSameLine {
            violations = validateKind(file,
                                      attributeShouldBeOnSameLine: attributeShouldBeOnSameLine,
                                      dictionary: dictionary)
        } else {
            violations = []
        }

        return validateFile(file, dictionary: dictionary) + violations
    }

    private func validateTestableImport(file: File) -> [StyleViolation] {
        let pattern = "@testable[\n]+\\s*import"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            let match = file.contents.substringWithByteRange(start: $0.location, length: $0.length)
            let location = (match?.lastIndexOf("import") ?? 0) + $0.location

            return StyleViolation(ruleDescription: self.dynamicType.description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: location))
        }
    }

    private func validateKind(file: File,
                              attributeShouldBeOnSameLine: Bool,
                              dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let attributes = parseAttributes(dictionary)

        guard !attributes.isEmpty,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let (lineNumber, _) = file.contents.lineAndCharacterForByteOffset(offset) else {
            return []
        }

        let line = file.lines[lineNumber - 1]

        let tokens = file.syntaxMap.tokensIn(line.byteRange)
        let attributesTokensWithRanges = tokens.flatMap { attributeName($0, file: file) }

        let attributesTokens = Set(attributesTokensWithRanges.map { $0.0 })
        var isViolation = false

        do {
            let previousAttributesWithParameters = try attributesFromPreviousLines(lineNumber - 1,
                                                                                   file: file)
            let previousAttributes = Set(previousAttributesWithParameters.map { $0.0 })

            let alwaysInSameLineAttributes = configuration.alwaysInSameLine
            let alwaysInNewLineAttributes =
                createAlwaysInNewLineAttributes(previousAttributesWithParameters,
                                                attributesTokens: attributesTokensWithRanges,
                                                line: line, file: file)

            if !attributesTokens.intersect(alwaysInNewLineAttributes).isEmpty {
                isViolation = true
            } else if !previousAttributes.intersect(alwaysInSameLineAttributes).isEmpty {
                isViolation = true
            } else {

                // ignore whitelisted attributes
                let operation: Set<String> -> Set<String> -> Set<String> =
                    attributeShouldBeOnSameLine ? Set.union : Set.subtract

                let attributesAfterWhitelist = operation(
                        operation(attributesTokens)(
                            previousAttributes.intersect(alwaysInNewLineAttributes)
                        )
                    )(attributesTokens.intersect(alwaysInSameLineAttributes))

                isViolation = attributesAfterWhitelist.isEmpty == attributeShouldBeOnSameLine
            }
        } catch {
            isViolation = true
        }

        guard isViolation else {
            return []
        }

        // Violation found!
        return violation(dictionary, file: file)
    }

    private func createAlwaysInNewLineAttributes(previousAttributesWithParameters: [(String, Bool)],
                                                 attributesTokens: [(String, NSRange)],
                                                 line: Line, file: File) -> [String] {
        let attributesTokensWithParameters: [(String, Bool)] = attributesTokens.map {
            let hasParameter = attributeContainsParameter($1, line: line, file: file)
            return ($0, hasParameter)
        }
        let allAttributes = previousAttributesWithParameters + attributesTokensWithParameters

        return allAttributes.flatMap { (token, hasParameter) -> String? in
            // an attribute should be on a new line if one of these is true:
            // 1. it's a parameterized attribute
            //      a. the parameter is on the token (i.e. warn_unused_result)
            //      b. the parameter was parsed in the `hasParameter` variable (most attributes)
            // 2. it's a whitelisted attribute, according to the current configuration
            let isParameterized = hasParameter || token.containsString("(")
            if isParameterized || configuration.alwaysInNewLine.contains(token) {
                return token
            }

            return nil
        }
    }

    private func violation(dictionary: [String: SourceKitRepresentable],
                           file: File) -> [StyleViolation] {
        let location: Location
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severityConfiguration.severity,
                location: location
            )
        ]
    }

    // returns an array with the token itself (i.e. "@objc") and whether it's parameterized
    // note: the parameter is not contained in the token
    private func attributesFromPreviousLines(lineNumber: Int,
                                             file: File) throws -> [(String, Bool)] {
        var currentLine = lineNumber - 1
        var allTokens = [(String, Bool)]()

        while currentLine >= 0 {
            let line = file.lines[currentLine]
            let tokens = file.syntaxMap.tokensIn(line.byteRange)

            if tokens.isEmpty {
                throw AttributesRuleError.UnexpectedBlankLine
            }

            let attributesTokens = tokens.flatMap { attributeName($0, file: file) }
            guard let firstTokenRange = attributesTokens.first?.1 else {
                // found a line that does not contain an attribute token - we can stop looking
                break
            }

            if attributesTokens.count > 1 {
                // we don't allow multiple attributes in the same line if it's a previous line
                throw AttributesRuleError.MoreThanOneAttributeInSameLine
            }

            let hasParameter = attributeContainsParameter(firstTokenRange, line: line, file: file)

            allTokens.insertContentsOf(attributesTokens.map { ($0.0, hasParameter) }, at: 0)
            currentLine -= 1
        }

        return allTokens
    }

    private func attributeContainsParameter(attributeRange: NSRange,
                                            line: Line, file: File) -> Bool {
        let restOfLineOffset = attributeRange.location + attributeRange.length
        let restOfLineLength = line.byteRange.location + line.byteRange.length - restOfLineOffset

        let range = NSRange(location: 0, length: restOfLineLength)
        let regex = AttributesRule.regularExpression

        // check if after the token is a `(` with only spaces allowed between the token and `(`
        guard let restOfLine = file.contents.substringWithByteRange(start: restOfLineOffset,
                                                                    length: restOfLineLength)
            where regex.firstMatchInString(restOfLine, options: [], range: range) != nil else {

            return false
        }

        return true
    }

    private func attributeName(token: SyntaxToken, file: File) -> (String, NSRange)? {
        guard SyntaxKind(rawValue: token.type) == .AttributeBuiltin else {
            return nil
        }

        let maybeName = file.contents.substringWithByteRange(start: token.offset,
                                                             length: token.length)
        if let name = maybeName where isAttribute(name) {
            return (name, NSRange(location: token.offset, length: token.length))
        }

        return nil
    }

    private func isAttribute(name: String) -> Bool {
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
        let attributes = (dictionary["key.attributes"] as? [SourceKitRepresentable])?
            .flatMap({ ($0 as? [String: SourceKitRepresentable]) as? [String: String] })
            .flatMap({ $0["key.attribute"] }) ?? []

        let blacklisted = Set(arrayLiteral: "source.decl.attribute.__raw_doc_comment",
                              "source.decl.attribute.mutating")
        return attributes.filter { !blacklisted.contains($0) }
    }
}

private struct AttributesRuleExamples {

    // swiftlint:disable:next function_body_length
    static func nonTriggeringExamples() -> [String] {
        let common = [
            "@objc var x: String",
            "@objc private var x: String",
            "@nonobjc var x: String",
            "@IBOutlet private var label: UILabel",
            "@IBOutlet @objc private var label: UILabel",
            "@NSCopying var name: NSString",
            "@NSManaged var name: String?",
            "@IBInspectable var cornerRadius: CGFloat",
            "@available(iOS 9.0, *)\n let stackView: UIStackView",
            "@NSManaged func addSomeObject(book: SomeObject)",
            "@IBAction func buttonPressed(button: UIButton)",
            "@objc\n @IBAction func buttonPressed(button: UIButton)",
            "@available(iOS 9.0, *)\n func animate(view: UIStackView)",
            "@available(iOS 9.0, *, message=\"A message\")\n func animate(view: UIStackView)",
            "@nonobjc\n final class X",
            "@available(iOS 9.0, *)\n class UIStackView",
            "@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate",
            "@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate",
            "@IBDesignable\n class MyCustomView: UIView",
            "@testable import SourceKittenFramework",
            "@objc(foo_x)\n var x: String",
            "@available(iOS 9.0, *)\n@objc(abc_stackView)\n let stackView: UIStackView",
            "@objc(abc_addSomeObject:)\n @NSManaged func addSomeObject(book: SomeObject)",
            "@objc(ABCThing)\n @available(iOS 9.0, *)\n class Thing"
        ]

        #if swift(>=3.0)
            let swift3Only = [
            "@GKInspectable var maxSpeed: Float",
            "@discardableResult\n func a() -> Int",
            "@objc\n @discardableResult\n func a() -> Int",
            "func increase(f: @autoclosure () -> Int) -> Int",
            "func foo(completionHandler: @escaping () -> Void)"
            ]

            return common + swift3Only
        #else
            let swift2Only = [
                "@warn_unused_result\n func a() -> Int",
                "@objc\n @warn_unused_result\n func a() -> Int",
                "func increase(@autoclosure f: () -> Int ) -> Int",
                "func foo(@noescape x: Int -> Int)",
                "@noreturn\n func exit(_: Int)",
                "func exit(_: Int) -> @noreturn Int"
            ]

            return common + swift2Only
        #endif
    }

    // swiftlint:disable:next function_body_length
    static func triggeringExamples() -> [String] {
        let common = [
            "@objc\n ↓var x: String",
            "@objc\n\n ↓var x: String",
            "@objc\n private ↓var x: String",
            "@nonobjc\n ↓var x: String",
            "@IBOutlet\n private ↓var label: UILabel",
            "@IBOutlet\n\n private ↓var label: UILabel",
            "@NSCopying\n ↓var name: NSString",
            "@NSManaged\n ↓var name: String?",
            "@IBInspectable\n ↓var cornerRadius: CGFloat",
            "@available(iOS 9.0, *) ↓let stackView: UIStackView",
            "@NSManaged\n ↓func addSomeObject(book: SomeObject)",
            "@IBAction\n ↓func buttonPressed(button: UIButton)",
            "@IBAction\n @objc\n ↓func buttonPressed(button: UIButton)",
            "@available(iOS 9.0, *) ↓func animate(view: UIStackView)",
            "@nonobjc final ↓class X",
            "@available(iOS 9.0, *) ↓class UIStackView",
            "@available(iOS 9.0, *)\n @objc ↓class UIStackView",
            "@available(iOS 9.0, *) @objc\n ↓class UIStackView",
            "@available(iOS 9.0, *)\n\n ↓class UIStackView",
            "@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate",
            "@IBDesignable ↓class MyCustomView: UIView",
            "@testable\n↓import SourceKittenFramework",
            "@testable\n\n\n↓import SourceKittenFramework",
            "@objc(foo_x) ↓var x: String",
            "@available(iOS 9.0, *) @objc(abc_stackView)\n ↓let stackView: UIStackView",
            "@objc(abc_addSomeObject:) @NSManaged\n ↓func addSomeObject(book: SomeObject)",
            "@objc(abc_addSomeObject:)\n @NSManaged\n ↓func addSomeObject(book: SomeObject)",
            "@available(iOS 9.0, *)\n @objc(ABCThing) ↓class Thing"
        ]

        #if swift(>=3.0)
            let swift3Only = [
            "@GKInspectable\n ↓var maxSpeed: Float",
            "@discardableResult ↓func a() -> Int",
            "@objc\n @discardableResult ↓func a() -> Int",
            "@objc\n\n @discardableResult\n ↓func a() -> Int",
            ]

            return common + swift3Only
        #else
            let swift2Only = [
                "@warn_unused_result ↓func a() -> Int",
                "@warn_unused_result(message=\"You should use this\") ↓func a() -> Int",
                "@objc\n @warn_unused_result ↓func a() -> Int",
                "@objc\n\n @warn_unused_result\n ↓func a() -> Int",
                "@noreturn ↓func exit(_: Int)"
            ]

            return common + swift2Only
        #endif
    }
}
