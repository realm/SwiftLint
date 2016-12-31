//
//  ExpressibleByArrayLiteralInitRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/31/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExpressibleByArrayLiteralInitRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "expressible_by_array_literal_init",
        name: "ExpressibleByArrayLiteral Init",
        description: "The initializer declared in ExpressibleByArrayLiteral procotol shouldn't be called directly.",
        nonTriggeringExamples: [
            "let set: Set<Int> = [1, 2]\n",
            "let set = Set(array)\n"
        ],
        triggeringExamples: [
            "let set = ↓Set(arrayLiteral: 1, 2)\n",
            "let set = ↓Set.init(arrayLiteral: 1, 2)\n"
        ]
    )

    public func validateFile(_ file: File, kind: SwiftExpressionKind,
                             dictionary: [String : SourceKitRepresentable]) -> [StyleViolation] {
        return violationRangesInFile(file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRangesInFile(_ file: File,
                                       kind: SwiftExpressionKind,
                                       dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .call,
            let name = dictionary["key.name"] as? String,
            ExpressibleByArrayLiteralInitRule.initCallNames.contains(name),
            case let arguments = dictionary.enclosedArguments.flatMap({ $0["key.name"] as? String }),
            arguments == ["arrayLiteral"],
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        return [range]
    }

    private static let initCallNames: Set<String> = {
        let types = [
            "Array",
            "ArraySlice",
            "ContiguousArray",
            "IndexPath",
            "NSArray",
            "NSCountedSet",
            "NSMutableArray",
            "NSMutableOrderedSet",
            "NSMutableSet",
            "NSOrderedSet",
            "NSSet",
            "SBElementArray",
            "Set"
        ]

        return Set(types.flatMap { [$0, "\($0).init"] })
    }()
}
