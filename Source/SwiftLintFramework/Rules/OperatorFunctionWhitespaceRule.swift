//
//  OperatorWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 8/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct OperatorFunctionWhitespaceRule: ASTRule {
    public init() {}

    public let identifier = "operator_whitespace"

    public func validateFile(file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation] {
        return (dictionary["key.substructure"] as? XPCArray ?? []).flatMap { subItem in
            var violations = [StyleViolation]()
            if let subDict = subItem as? XPCDictionary,
                let kindString = subDict["key.kind"] as? String,
                let kind = flatMap(kindString, { SwiftDeclarationKind(rawValue: $0) }) {
                    violations.extend(validateFile(file, dictionary: subDict))
                    violations.extend(validateFile(file, kind: kind, dictionary: subDict))
            }
            return violations
        }
    }

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
        let functionKinds: [SwiftDeclarationKind] = [
            .FunctionFree,
        ]
        if !contains(functionKinds, kind) {
            return []
        }
        var violations = [StyleViolation]()
        if let nameOffset = flatMap(dictionary["key.nameoffset"] as? Int64, { Int($0) }),
            let nameLength = flatMap(dictionary["key.namelength"] as? Int64, { Int($0) }),
            let offset = flatMap(dictionary["key.offset"] as? Int64, { Int($0) }) {

            let location = Location(file: file, offset: offset)
            let startAdvance = advance(file.contents.startIndex, nameOffset)
            let endAdvance = advance(startAdvance, nameLength)
            let range = Range<String.Index>(start: startAdvance, end: endAdvance)
            let definition = file.contents.substringWithRange(range)

            let ope1 = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", "."].map({ "\\\($0)" })
            let ope2 = ["%", "<", ">", "&"]
            let ope = "".join(ope1 + ope2)
            let pattern = "^[\(ope)]+(<[A-Z]+>)?\\("

            if let regex = NSRegularExpression(pattern: pattern, options: nil, error: nil) {
                let matchRange = NSRange(location: 0, length: count(definition.utf16))
                let matches = regex.matchesInString(definition, options: nil, range: matchRange)

                if matches.count > 0 {
                    violations.append(StyleViolation(type: .OperatorFunctionWhitespace,
                        location: location,
                        severity: .Medium,
                        reason: "Use whitespace around operators when defining them"))
                }
            }
        }
        return violations
    }

    public let example = RuleExample(
        ruleName: "Operator Function Whitespace Rule",
        ruleDescription: "Use whitespace around operators when defining them.",
        nonTriggeringExamples: [
            "func <| (lhs: Int, rhs: Int) -> Int {}\n",
            "func <|< <A>(lhs: A, rhs: A) -> A {}\n",
            "func abc(lhs: Int, rhs: Int) -> Int {}\n"
        ],
        triggeringExamples: [
            "func <|(lhs: Int, rhs: Int) -> Int {}\n",
            "func <|<<A>(lhs: A, rhs: A) -> A {}\n"
        ]
    )
}
