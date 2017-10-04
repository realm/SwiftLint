//
//  SyntacticSugarRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 21/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SyntacticSugarRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "syntactic_sugar",
        name: "Syntactic Sugar",
        description: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "let x: [Int]",
            "let x: [Int: String]",
            "let x: Int?",
            "func x(a: [Int], b: Int) -> [Int: Any]",
            "let x: Int!",
            "extension Array { \n func x() { } \n }",
            "extension Dictionary { \n func x() { } \n }",
            "let x: CustomArray<String>",
            "var currentIndex: Array<OnboardingPage>.Index?",
            "func x(a: [Int], b: Int) -> Array<Int>.Index",
            "unsafeBitCast(nonOptionalT, to: Optional<T>.self)",
            "type is Optional<String>.Type",
            "let x: Foo.Optional<String>"
        ],
        triggeringExamples: [
            "let x: ↓Array<String>",
            "let x: ↓Dictionary<Int, String>",
            "let x: ↓Optional<Int>",
            "let x: ↓ImplicitlyUnwrappedOptional<Int>",
            "func x(a: ↓Array<Int>, b: Int) -> [Int: Any]",
            "func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>",
            "func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>",
            "let x = ↓Array<String>.array(of: object)",
            "let x: ↓Swift.Optional<String>"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let types = ["Optional", "ImplicitlyUnwrappedOptional", "Array", "Dictionary"]
        let negativeLookBehind = "(?:(?<!\\.)|Swift\\.)"
        let pattern = negativeLookBehind + "\\b(" + types.joined(separator: "|") + ")\\s*<.*?>"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        let contents = file.contents.bridge()
        let range = NSRange(location: 0, length: contents.length)

        return regex(pattern).matches(in: file.contents, options: [], range: range).flatMap { result in
            let range = result.range
            guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
                return nil
            }

            let kinds = file.syntaxMap.kinds(inByteRange: byteRange)
            guard excludingKinds.isDisjoint(with: kinds),
                isValidViolation(range: range, file: file) else {
                    return nil
            }

            let typeString = contents.substring(with: result.range(at: 1))
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: message(for: typeString))

        }
    }

    private func isValidViolation(range: NSRange, file: File) -> Bool {
        let contents = file.contents.bridge()

        // avoid triggering when referring to an associatedtype
        let start = range.location + range.length
        let restOfFileRange = NSRange(location: start, length: contents.length - start)
        if regex("\\s*\\.").firstMatch(in: file.contents, options: [],
                                       range: restOfFileRange)?.range.location == start {
            guard let byteOffset = contents.NSRangeToByteRange(start: range.location,
                                                               length: range.length)?.location else {
                return false
            }

            let kinds = file.structure.kinds(forByteOffset: byteOffset)
                .flatMap { SwiftExpressionKind(rawValue: $0.kind) }
            guard kinds.contains(.call) else {
                return false
            }

            if let (range, kinds) = file.match(pattern: "\\s*\\.(?:self|Type)", range: restOfFileRange).first,
                range.location == start, kinds == [.keyword] || kinds == [.identifier] {
                return false
            }
        }

        return true
    }

    private func message(for originalType: String) -> String {
        let typeString: String
        let sugaredType: String

        switch originalType {
        case "Optional":
            typeString = "Optional<Int>"
            sugaredType = "Int?"
        case "ImplicitlyUnwrappedOptional":
            typeString = "ImplicitlyUnwrappedOptional<Int>"
            sugaredType = "Int!"
        case "Array":
            typeString = "Array<Int>"
            sugaredType = "[Int]"
        case "Dictionary":
            typeString = "Dictionary<String, Int>"
            sugaredType = "[String: Int]"
        default:
            return type(of: self).description.description
        }

        return "Shorthand syntactic sugar should be used, i.e. \(sugaredType) instead of \(typeString)."
    }
}
