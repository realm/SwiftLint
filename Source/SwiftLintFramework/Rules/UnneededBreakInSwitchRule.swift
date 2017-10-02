//
//  UnneededBreakInSwitchRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func embedInSwitch(_ text: String, case: String = "case .bar") -> String {
    return "switch foo {\n" +
            "\(`case`):\n" +
           "    \(text)\n" +
           "}"
}
public struct UnneededBreakInSwitchRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unneeded_break_in_switch",
        name: "Unneeded Break in Switch",
        description: "Avoid using unneeded break statements.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            embedInSwitch("break"),
            embedInSwitch("break", case: "default"),
            embedInSwitch("for i in [0, 1, 2] { break }"),
            embedInSwitch("if true { break }"),
            embedInSwitch("something()")
        ],
        triggeringExamples: [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "break", with: [.keyword]).flatMap { range in
            let contents = file.contents.bridge()
            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length),
                let innerStructure = file.structure.structures(forByteOffset: byteRange.location).last,
                innerStructure.kind.flatMap(StatementKind.init) == .case,
                let caseOffset = innerStructure.offset,
                let caseLength = innerStructure.length,
                let lastPatternEnd = patternEnd(dictionary: innerStructure) else {
                    return nil
            }

            let caseRange = NSRange(location: caseOffset, length: caseLength)
            let tokens = file.syntaxMap.tokens(inByteRange: caseRange).filter { token in
                guard let kind = SyntaxKind(rawValue: token.type),
                    token.offset > lastPatternEnd else {
                        return false
                }

                return !kind.isCommentLike
            }

            // is the `break` the only token inside `case`? If so, it's valid.
            guard tokens.count > 1 else {
                return nil
            }

            // is the `break` found the last (non-comment) token inside `case`?
            guard let lastValidToken = tokens.last,
                SyntaxKind(rawValue: lastValidToken.type) == .keyword,
                lastValidToken.offset == byteRange.location,
                lastValidToken.length == byteRange.length else {
                    return nil
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

    private func patternEnd(dictionary: [String: SourceKitRepresentable]) -> Int? {
        let patternEnds = dictionary.elements.flatMap { subDictionary -> Int? in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length else {
                    return nil
            }

            return offset + length
        }

        return patternEnds.max()
    }
}

private extension Structure {
    func structures(forByteOffset byteOffset: Int) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()

        func parse(_ dictionary: [String: SourceKitRepresentable]) {
            guard let offset = dictionary.offset,
                let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }),
                NSLocationInRange(byteOffset, byteRange) else {
                    return
            }

            results.append(dictionary)
            dictionary.substructure.forEach(parse)
        }
        parse(dictionary)
        return results
    }
}
