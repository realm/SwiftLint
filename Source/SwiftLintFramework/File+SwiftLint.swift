//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

typealias Line = (index: Int, content: String)

extension File {
    public func matchPattern(pattern: String, withSyntaxKinds syntaxKinds: [SyntaxKind] = []) ->
        [NSRange] {
        return flatMap(NSRegularExpression(pattern: pattern, options: nil, error: nil)) { regex in
            let range = NSRange(location: 0, length: count(self.contents.utf16))
            let syntax = SyntaxMap(file: self)
            let matches = regex.matchesInString(self.contents, options: nil, range: range)
            return map(matches as? [NSTextCheckingResult]) { matches in
                return compact(matches.map { match in
                    let tokensInRange = syntax.tokens.filter {
                        NSLocationInRange($0.offset, match.range)
                    }
                    let kindsInRange = compact(map(tokensInRange) {
                        SyntaxKind(rawValue: $0.type)
                    })
                    if kindsInRange.count != syntaxKinds.count {
                        return nil
                    }
                    for (index, kind) in enumerate(syntaxKinds) {
                        if kind != kindsInRange[index] {
                            return nil
                        }
                    }
                    return match.range
                })
            }
        } ?? []
    }

    func astViolationsInDictionary(dictionary: XPCDictionary) -> [StyleViolation] {
        return (dictionary["key.substructure"] as? XPCArray ?? []).flatMap { subItem in
            var violations = [StyleViolation]()
            if let subDict = subItem as? XPCDictionary,
                let kindString = subDict["key.kind"] as? String,
                let kind = flatMap(kindString, { SwiftDeclarationKind(rawValue: $0) }) {
                violations.extend(self.astViolationsInDictionary(subDict))
                violations.extend(TypeNameRule.validateFile(self, kind: kind, dictionary: subDict))
                violations.extend(VariableNameRule.validateFile(self, kind: kind, dictionary: subDict))
                violations.extend(TypeBodyLengthRule.validateFile(self, kind: kind, dictionary: subDict))
                violations.extend(FunctionBodyLengthRule.validateFile(self, kind: kind, dictionary: subDict))
                violations.extend(self.validateNesting(kind, dict: subDict))
            }
            return violations
        }
    }

    func validateNesting(kind: SwiftDeclarationKind, dict: XPCDictionary, level: Int = 0) -> [StyleViolation] {
        var violations = [StyleViolation]()
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum,
            .Enumelement
        ]
        if let offset = flatMap(dict["key.offset"] as? Int64, { Int($0) }) {
            if level > 1 && contains(typeKinds, kind) {
                violations.append(StyleViolation(type: .Nesting,
                    location: Location(file: self, offset: offset),
                    reason: "Types should be nested at most 1 level deep"))
            } else if level > 5 {
                violations.append(StyleViolation(type: .Nesting,
                    location: Location(file: self, offset: offset),
                    reason: "Statements should be nested at most 5 levels deep"))
            }
        }
        violations.extend(compact((dict["key.substructure"] as? XPCArray ?? []).map { subItem in
            let subDict = subItem as? XPCDictionary
            let kindString = subDict?["key.kind"] as? String
            let kind = flatMap(kindString) { kindString in
                return SwiftDeclarationKind(rawValue: kindString)
            }
            if let kind = kind, subDict = subDict {
                return (kind, subDict)
            }
            return nil
        } as [(SwiftDeclarationKind, XPCDictionary)?]).flatMap { (kind, dict) in
            self.validateNesting(kind, dict: dict, level: level + 1)
        })
        return violations
    }

    internal var stringViolations: [StyleViolation] {
        let lines = contents.lines()
        // FIXME: Using '+' to concatenate these arrays would be nicer,
        //        but slows the compiler to a crawl.
        var violations = LineLengthRule.validateFile(self)
        violations.extend(LeadingWhitespaceRule.validateFile(self))
        violations.extend(TrailingWhitespaceRule.validateFile(self))
        violations.extend(TrailingNewlineRule.validateFile(self))
        violations.extend(ForceCastRule.validateFile(self))
        violations.extend(FileLengthRule.validateFile(self))
        violations.extend(TodoRule.validateFile(self))
        violations.extend(ColonRule.validateFile(self))
        return violations
    }
}
