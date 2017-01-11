//
//  ShorthandOperatorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ShorthandOperatorRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "shorthand_operator",
        name: "Shorthand Operator",
        description: "Prefer shorhand operators (+=, -=, *=, /=) over doing the operation and assigning.",
        nonTriggeringExamples: allOperators.flatMap { operation in
            [
                "foo \(operation)= 1",
                "foo \(operation)= variable",
                "foo \(operation)= bar.method()",
                "self.foo = foo \(operation) 1",
                "foo = self.foo \(operation) 1",
                "page = ceilf(currentOffset \(operation) pageWidth)",
                "foo = aMethod(foo \(operation) bar)",
                "foo = aMethod(bar \(operation) foo)"
            ]
        },
        triggeringExamples: allOperators.flatMap { operation in
            [
                "↓foo = foo \(operation) 1\n",
                "↓foo = foo \(operation) aVariable\n",
                "↓foo = foo \(operation) bar.method()\n",
                "↓foo.aProperty = foo.aProperty \(operation) 1\n",
                "↓self.aProperty = self.aProperty \(operation) 1\n"
            ]

        } + commutativeOperators.flatMap { operation in
            [
                "↓foo = 1 \(operation) foo\n",
                "↓foo = aVariable \(operation) foo\n",
                "↓foo = bar.method() \(operation) foo\n",
                "↓foo = bar.method(param: 1, otherParam: 2) \(operation) foo\n"
            ]
        }
    )

    private static let allOperators = ["-", "/"] + commutativeOperators
    private static let commutativeOperators = ["+", "*"]

    private static let pattern: String = {
        let escaped = { (operators: [String]) -> String in
            return "[\(operators.map { "\\\($0)" }.joined())]"
        }

        let escapedCommutativeOperators = escaped(commutativeOperators)
        let escapedOperators = escaped(allOperators)

        let operand = "[\\w\\d\\.]+?"
        let spaces = "[^\\S\\r\\n]*?"
        let otherOperand = "\(spaces).+?\(spaces)"

        let pattern1 = "^\(spaces)(\(operand))\(spaces)=\(spaces)(\\1)\(spaces)\(escapedOperators)"
        let pattern2 = "^\(spaces)(\(operand))\(spaces)=\(otherOperand)\(escapedCommutativeOperators)\(spaces)(\\3)$"

        return "\(pattern1)|\(pattern2)"
    }()

    private static let violationRegex = regex(pattern, options: [.anchorsMatchLines])

    public func validate(file: File) -> [StyleViolation] {
        let contents = file.contents.bridge()
        let range = NSRange(location: 0, length: contents.length)

        let matches = ShorthandOperatorRule.violationRegex.matches(in: file.contents, options: [], range: range)
        return matches.flatMap { match -> StyleViolation? in

            // byteRanges will have the ranges of captured groups
            let byteRanges: [NSRange?] = (1..<match.numberOfRanges).map { rangeIdx in
                let range = match.rangeAt(rangeIdx)
                guard range.location != NSNotFound else {
                    return nil
                }

                return contents.NSRangeToByteRange(start: range.location, length: range.length)
            }

            guard byteRanges[0] != nil || byteRanges[2] != nil else {
                return nil
            }

            let kindsInCaptureGroups = byteRanges.map { range -> [SyntaxKind] in
                range.flatMap {
                    let tokens = file.syntaxMap.tokens(inByteRange: $0)
                    return tokens.flatMap { SyntaxKind(rawValue: $0.type) }
                } ?? []
            }

            let groupIndexes: [Int]
            if byteRanges[0] != nil {
                // it's a match from pattern1
                groupIndexes = [0, 1]
            } else {
                // it's a match from pattern2
                groupIndexes = [2, 3]
            }

            for idx in groupIndexes where !Set(kindsInCaptureGroups[idx]).isSubset(of: [.identifier, .keyword]) {
                return nil
            }

            let byteRange = byteRanges[groupIndexes[0]]!
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: byteRange.location))
        }
    }
}
