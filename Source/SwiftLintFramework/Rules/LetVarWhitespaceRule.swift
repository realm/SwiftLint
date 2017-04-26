//
//  LetVarWhitespaceRule.swift
//  SwiftLint
//
//  Created by David Catmull on 4/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LetVarWhitespaceRule: OptInRule {

    public var configurationDescription: String { return "" }

    public init() {}
    public init(configuration: Any) {}

    public static let description = RuleDescription(
        identifier: "let_var_whitespace",
        name: "Variable Declaration Whitespace",
        description: "Let and var should be separated from other statements by a blank line.",
        nonTriggeringExamples: [
            "let a = 0\nvar x = 1\n\nx = 2\n",
            "a = 5\n\nvar x = 1\n",
            "struct X {\n\tvar a = 0\n}\n",
            "let a = 1 +\n\t2\nlet b = 5\n"
        ],
        triggeringExamples: [
            "var x = 1\n↓x = 2\n",
            "↓a = 5\nvar x = 1\n",
            "struct X {\n\tlet a\n\t↓func x() {}\n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let varLines = varLetLineNumbers(file: file, structure: file.structure.dictionary.substructure)
        let commentLines = commentLineNumbers(file: file)
        var violations = [StyleViolation]()
        let notWhitespace = CharacterSet.whitespaces.inverted
        
        for (index, line) in file.lines.enumerated() {
            guard !varLines.contains(index) &&
                  !commentLines.contains(index) else {
                continue
            }
            
            let lastRange = line.content.rangeOfCharacter(from: notWhitespace, options: [.backwards])
            let firstRange = line.content.rangeOfCharacter(from: notWhitespace)
            
            // Precedes var/let and has text not ending with {
            if linePrecedesVar(index, varLines, commentLines) {
                if let last = lastRange.map({ line.content.substring(with: $0) }), last != "{" {
                    violated(&violations, file, index)
                }
            }
            // Follows var/let and has text not starting with }
            if lineFollowsVar(index, varLines, commentLines) {
                if let first = firstRange.map({ line.content.substring(with: $0) }), first != "}" {
                    violated(&violations, file, index)
                }
            }
        }
        return violations
    }
    
    func linePrecedesVar(_ lineNumber: Int, _ varLines: Set<Int>, _ commentLines: Set<Int>) -> Bool {
        return lineNeighborsVar(lineNumber, varLines, commentLines, 1)
    }
    
    func lineFollowsVar(_ lineNumber: Int, _ varLines: Set<Int>, _ commentLines: Set<Int>) -> Bool {
        return lineNeighborsVar(lineNumber, varLines, commentLines, -1)
    }
    
    func lineNeighborsVar(_ lineNumber: Int, _ varLines: Set<Int>, _ commentLines: Set<Int>, _ increment: Int) -> Bool {
        if varLines.contains(lineNumber + increment) {
            return true
        }
        
        var prevLine = lineNumber
        
        while commentLines.contains(prevLine) {
            if varLines.contains(prevLine + increment) {
                return true
            }
            prevLine += increment
        }
        return false
    }
    
    func violated(_ violations: inout [StyleViolation], _ file: File, _ line: Int) {
        let content = file.lines[line].content
        let startIndex = content.rangeOfCharacter(from: CharacterSet.whitespaces.inverted)?.lowerBound ?? content.startIndex
        let offset = content.characters.distance(from: content.startIndex, to: startIndex)
        
        violations.append(StyleViolation(ruleDescription: LetVarWhitespaceRule.description, location: Location(file: file, characterOffset: offset + file.lines[line].range.location)))
    }
    
    // Collects all the line numbers containing var or let declarations
    func varLetLineNumbers(file: File, structure: [[String: SourceKitRepresentable]]) -> Set<Int> {
        var result = Set<Int>()
        
        for statement in structure {
            guard let kind = statement.kind else {
                continue
            }
            
            switch kind {
            case SwiftDeclarationKind.varGlobal.rawValue,
                 SwiftDeclarationKind.varClass.rawValue,
                 SwiftDeclarationKind.varLocal.rawValue,
                 SwiftDeclarationKind.varInstance.rawValue:
                guard let offset = statement.offset,
                      let length = statement.length else {
                    break
                }
                let startLine = file.line(for: offset, startFrom: 0)
                let endLine = file.line(for: offset + length, startFrom: startLine)
                
                for lineNumber in startLine...endLine {
                    result.update(with: lineNumber)
                }
            default:
                break
            }
            if statement["key.substructure"] != nil {
                result.formUnion(varLetLineNumbers(file: file, structure: statement.substructure))
            }
        }
        return result
    }

    // Collects all the line numbers containing comments
    func commentLineNumbers(file: File) -> Set<Int> {
        var result = Set<Int>()
        let syntaxMap = file.syntaxMap

        for token in syntaxMap.tokens where token.type == SyntaxKind.comment.rawValue {
            let startLine = file.line(for: token.offset, startFrom: 0)
            let endLine = file.line(for: token.offset + token.length, startFrom: startLine)

            for lineNumber in startLine...endLine {
                result.update(with: lineNumber)
            }
        }
        return result
    }
}

extension File {
    func line(for offset: Int, startFrom: Int) -> Int {
        for index in startFrom..<lines.count {
            let line = lines[index]
            
            if line.byteRange.location + line.byteRange.length > offset {
                return index
            }
        }
        return 0
    }
}

extension CharacterSet {
    var inverted: CharacterSet {
        var other = self
        
        other.invert()
        return other
    }
}
