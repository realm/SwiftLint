//
//  ConditionalBindingCascadeRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 08/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ConditionalBindingCascadeRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_binding_cascade",
        name: "Conditional Binding Cascade",
        description: "Repeated `let` statements in conditional binding cascade should be avoided.",
        nonTriggeringExamples: [
            "if let a = b, c = d {",
            "if let a = b, \n c = d {",
            "if let a = b, \n c = d \n {",
            "if let a = b { if let c = d {",
            "if let a = b { let c = d({ foo in ... })",
            "guard let a = b, c = d else {",
            "guard let a = b where a, let c = d else {",
            "guard let foo = someOptional(), var bar = someMutableOptional(foo) else { return }",
        ],
        triggeringExamples: [
            "if let a = b, let c = d {",
            "if let a = b, \n let c = d {",
            "if let a = b, c = d, let e = f {",
            "if let a = b, let c = d \n {",
            "if \n let a = b, let c = d {",
            "if let a = b, c = d.indexOf({$0 == e}), let f = g {",
            "guard let a = b, let c = d else {",
            "if let a = a, b = b {\ndebugPrint(\"\")\n}\nif let c = a, let d = b {\n}",
        ]
    )

    private static let kinds = [StatementKind.Guard, .If].map { $0.rawValue }
    public func validateFile(file: File, kind: String,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard self.dynamicType.kinds.contains(kind),
            let elements = dictionary["key.elements"] as? [SourceKitRepresentable] else {
            return []
        }
        let conditionByteRanges = elements
            .filter { $0.kind == "source.lang.swift.structure.elem.condition_expr" }
            .flatMap { return $0.byteRange }
        let contents = file.contents as NSString
        let resultsArray: [[StyleViolation]] = conditionByteRanges.map { conditionByteRange in
            let substructureRanges = dictionary.substructure?.flatMap { $0.byteRange }
                .filter { NSLocationInRange($0.location, conditionByteRange) } ?? []
            let keywordTokensInRange = file.syntaxMap.tokensIn(conditionByteRange)
                .filter { token in
                    // exclude tokens in sub structures
                    substructureRanges.indexOf { NSLocationInRange(token.offset, $0) } == nil
                }
                .filter { $0.type == SyntaxKind.Keyword.rawValue }
            let byteOffsetAndKeywords = keywordTokensInRange.map {
                ($0.offset, contents.substringWithByteRange(start: $0.offset, length: $0.length)!)
            }

            var results = [StyleViolation]()
            var previousBindingKeyword = ""
            for (byteOffset, keyword) in byteOffsetAndKeywords {
                switch keyword {
                case "let": fallthrough
                case "var":
                    if previousBindingKeyword == keyword {
                        results.append(StyleViolation(ruleDescription: self.dynamicType.description,
                            severity: configuration.severity,
                            location: Location(file: file, byteOffset: byteOffset)))
                    } else {
                        previousBindingKeyword = keyword
                    }
                case "where":
                    previousBindingKeyword = ""
                default:
                    break
                }
            }
            return results
        }

        return Array(resultsArray.flatten())
    }
}

extension SourceKitRepresentable {
    var dictionary: [String: SourceKitRepresentable]? {
        return self as? [String: SourceKitRepresentable]
    }

    var substructure: [SourceKitRepresentable]? {
        return dictionary?["key.substructure"] as? [SourceKitRepresentable]
    }

    var int: Int? {
        guard let int64 = self as? Int64 else { return nil }
        return Int(int64)
    }

    var kind: String? {
        return dictionary?["key.kind"] as? String
    }

    var byteRange: NSRange? {
        guard let byteOffset = dictionary?["key.offset"]?.int,
            byteLength = dictionary?["key.length"]?.int else { return nil }
        return NSRange(location: byteOffset, length: byteLength)
    }
}
