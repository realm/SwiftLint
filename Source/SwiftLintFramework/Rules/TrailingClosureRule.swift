//
//  TrailingClosureRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct TrailingClosureRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible",
        nonTriggeringExamples: [
            "foo.map { $0 + 1 }\n",
            "foo.bar()\n",
            "foo.reduce(0) { $0 + 1 }\n",
            "if let foo = bar.map({ $0 + 1 }) { }\n"
        ],
        triggeringExamples: [
            "↓foo.map({ $0 + 1 })\n",
            "↓foo.reduce(0, combine: { $0 + 1 })\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationOffsets(for: file.structure.dictionary, file: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationOffsets(for dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {
        var results = [Int]()

        if (dictionary["key.kind"] as? String).flatMap(SwiftExpressionKind.init) == .call,
            shouldBeTrailingClosure(dictionary: dictionary, file: file),
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {

            results = [offset]
        }

        if let kind = (dictionary["key.kind"] as? String).flatMap(StatementKind.init), kind != .brace {
            // trailing closures are not allowed in `if`, `guard`, etc
            results += dictionary.substructure.flatMap { subDict -> [Int] in
                guard (subDict["key.kind"] as? String).flatMap(StatementKind.init) == .brace else {
                    return []
                }

                return violationOffsets(for: subDict, file: file)
            }
        } else {
            results += dictionary.substructure.flatMap { subDict in
                violationOffsets(for: subDict, file: file)
            }
        }

        return results
    }

    private func shouldBeTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        let arguments = dictionary.enclosedArguments

        // check if last parameter should be trailing closure
        if arguments.count > 1,
            let lastArgument = dictionary.enclosedArguments.last,
            (lastArgument["key.name"] as? String) != nil,
            let offset = (lastArgument["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let length = (lastArgument["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
            let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location {
            return true
        }

        // check if there's only one unnamed parameter that is a closure
        if arguments.isEmpty,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let totalLength = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let nameOffset = (dictionary["key.nameoffset"] as? Int64).flatMap({ Int($0) }),
            let nameLength = (dictionary["key.namelength"] as? Int64).flatMap({ Int($0) }),
            case let start = nameOffset + nameLength,
            case let length = totalLength + offset - start,
            let range = file.contents.bridge().byteRangeToNSRange(start: start, length: length),
            let match = regex("\\s*\\(\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location {
            return true
        }

        return false
    }
}
