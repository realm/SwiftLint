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
        description: "Prefer shorthand operators (+=, -=, *=, /=) over doing the operation and assigning.",
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
        } + [
            "var helloWorld = \"world!\"\n helloWorld = \"Hello, \" + helloWorld",
            "angle = someCheck ? angle : -angle",
            "seconds = seconds * 60 + value"
        ],
        triggeringExamples: allOperators.flatMap { operation in
            [
                "↓foo = foo \(operation) 1\n",
                "↓foo = foo \(operation) aVariable\n",
                "↓foo = foo \(operation) bar.method()\n",
                "↓foo.aProperty = foo.aProperty \(operation) 1\n",
                "↓self.aProperty = self.aProperty \(operation) 1\n"
            ]
        } + [
            "n = n + i / outputLength",
            "n = n - i / outputLength"
//            "d = d * 60 * 60"
        ]
    )

    private static let allOperators = ["-", "/", "+", "*"]

    private static let pattern: String = {
        let escaped = { (operators: [String]) -> String in
            return "[\(operators.map { "\\\($0)" }.joined())]"
        }

        let escapedAll = escaped(allOperators)
        let operatorsWithoutPrecedence = escaped(["-", "+"])
        let operatorsWithPrecedence = escaped(["/", "*"])
        let operand = "[\\w\\d\\.]+?"
        let spaces = "[^\\S\\r\\n]*?"

        let pattern1 = "\(operatorsWithoutPrecedence)"
        let pattern2 = "\(operatorsWithPrecedence)\(spaces)\\S+$"
        return "^\(spaces)(\(operand))\(spaces)=\(spaces)(\\1)\(spaces)(\(pattern1)|\(pattern2))"
    }()

    private static let violationRegex: NSRegularExpression = {
        return regex(pattern, options: [.anchorsMatchLines])
    }()

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

            guard let byteRange = byteRanges[0] else {
                return nil
            }

            let kindsInCaptureGroups = byteRanges.map { range -> [SyntaxKind] in
                return range.flatMap(file.syntaxMap.kinds(inByteRange:)) ?? []
            }

            guard kindsAreValid(kindsInCaptureGroups[0]) &&
                kindsAreValid(kindsInCaptureGroups[1]) else {
                    return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: byteRange.location))
        }
    }

    private func kindsAreValid(_ kinds: [SyntaxKind]) -> Bool {
        return Set(kinds).isSubset(of: [.identifier, .keyword])
    }
}
