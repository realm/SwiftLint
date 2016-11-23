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
}

public struct AttributesRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "attributes_rule",
        name: "Attributes",
        description: "Attributes should be on their own lines in functions and types, " +
                     "but on the same line as variables and imports",
        nonTriggeringExamples: [
            "@objc var x: String",
            "@objc private var x: String",
            "@nonobjc var x: String",
            "@IBOutlet private var label: UILabel",
            "@NSCopying var name: NSString",
            "@NSManaged var name: String?",
            "@GKInspectable var maxSpeed: Float",
            "@IBInspectable var cornerRadius: CGFloat",
            "@available(iOS 9.0)\n let stackView: UIStackView",
            "@discardableResult\n func a() -> Int",
            "@objc\n @discardableResult\n func a() -> Int",
            "@NSManaged func addSomeObject(book: SomeObject)",
            "@IBAction func buttonPressed(button: UIButton)",
            "@available(iOS 9.0)\n func animate(view: UIStackView)",
            "@nonobjc\n final class X",
            "@available(iOS 9.0)\n class UIStackView",
            "@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate",
            "@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate",
            "@IBDesignable\n class MyCustomView: UIView",
            "@testable import SourceKittenFramework"
        ],
        triggeringExamples: [
            "@objc\n var x: String",
            "@objc\n\n var x: String",
            "@objc\n private var x: String",
            "@nonobjc\n var x: String",
            "@IBOutlet\n private var label: UILabel",
            "@IBOutlet\n\n private var label: UILabel",
            "@NSCopying\n var name: NSString",
            "@NSManaged\n var name: String?",
            "@GKInspectable\n var maxSpeed: Float",
            "@IBInspectable\n var cornerRadius: CGFloat",
            "@available(iOS 9.0) let stackView: UIStackView",
            "@discardableResult func a() -> Int",
            "@objc\n @discardableResult func a() -> Int",
            "@objc\n\n @discardableResult\n func a() -> Int",
            "@NSManaged\n func addSomeObject(book: SomeObject)",
            "@IBAction\n func buttonPressed(button: UIButton)",
            "@available(iOS 9.0) func animate(view: UIStackView)",
            "@nonobjc final class X",
            "@available(iOS 9.0) class UIStackView",
            "@available(iOS 9.0)\n\n class UIStackView",
            "@UIApplicationMain class AppDelegate: NSObject, UIApplicationDelegate",
            "@IBDesignable class MyCustomView: UIView",
            "@testable\nimport SourceKittenFramework",
            "@testable\n\n\nimport SourceKittenFramework"
        ]
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
        let pattern = "@testable[\n]+\\s*import*"
        let excludingKinds = SyntaxKind.commentAndStringKinds()
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: self.configuration.severity,
                location: Location(file: file, byteOffset: $0.location))
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
        let attributesTokens = tokens.flatMap { attributeName($0, file: file) }
        let isViolation: Bool

        do {
            let previousAttributes = try attributesFromPreviousLines(lineNumber - 1, file: file)

            let alwaysInSameLineAttributes = ["@IBAction", "@NSManaged"]
            let alwaysInNewLineAttributes = ["@available"]

            if !previousAttributes.filter(alwaysInNewLineAttributes.contains).isEmpty {
                isViolation = false
            } else if !attributesTokens.filter(alwaysInNewLineAttributes.contains).isEmpty {
                isViolation = true
            } else if !previousAttributes.filter(alwaysInSameLineAttributes.contains).isEmpty {
                isViolation = true
            } else if !attributesTokens.filter(alwaysInSameLineAttributes.contains).isEmpty {
                isViolation = false
            } else {
                isViolation = attributesTokens.isEmpty == attributeShouldBeOnSameLine
            }
        } catch {
            isViolation = true
        }

        guard isViolation else {
            return []
        }

        // Violation found!
        let location: Location
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: location
            )
        ]
    }

    private func attributesFromPreviousLines(lineNumber: Int, file: File) throws -> [String] {
        var currentLine = lineNumber - 1
        var allTokens = [String]()

        while currentLine >= 0 {
            let line = file.lines[currentLine]
            let tokens = file.syntaxMap.tokensIn(line.byteRange)

            if tokens.isEmpty {
                throw AttributesRuleError.UnexpectedBlankLine
            }

            let attributesTokens = tokens.flatMap { attributeName($0, file: file) }
            // found a line that does not contain an attribute token - we can stop looking
            if attributesTokens.isEmpty {
                break
            }

            allTokens.insertContentsOf(attributesTokens, at: 0)
            currentLine -= 1
        }

        return allTokens
    }

    private func attributeName(token: SyntaxToken, file: File) -> String? {
        guard SyntaxKind(rawValue: token.type) == .AttributeBuiltin else {
            return nil
        }

        let maybeName = file.contents.substringWithByteRange(start: token.offset,
                                                             length: token.length)
        if let name = maybeName where isAttribute(name) {
            return name
        }

        return nil
    }

    private func isAttribute(name: String) -> Bool {
        // all attributes start with @
        return name.hasPrefix("@")
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
