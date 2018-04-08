//
//  XCTSpecificMatcher.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/6/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct XCTSpecificMatcherRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xct_specific_matcher",
        name: "XCTest Specific Matcher",
        description: "Prefer specific XCTest matchers over `XCTAssertEqual` and `XCTAssertNotEqual`",
        kind: .idiomatic,
        nonTriggeringExamples: XCTSpecificMatcherRuleExamples.nonTriggeringExamples,
        triggeringExamples: XCTSpecificMatcherRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            let name = dictionary.name,
            let matcher = XCTestMatcher(rawValue: name) else { return [] }

        /*
         *  - Get the first two arguments and creates an array where the protected
         *    word is the first one (if any).
         */
        let arguments = dictionary.substructure
            .filter { $0.offset != nil }
            .sorted { arg1, arg2 -> Bool in
                guard
                    let firstOffset = arg1.offset,
                    let secondOffset = arg2.offset else { return false }

                return firstOffset < secondOffset
            }
            .prefix(2)
            .compactMap { argument -> String? in
                guard
                    let argOffset = argument.offset,
                    let argLength = argument.length,
                    let body = file.contents.bridge().substringWithByteRange(start: argOffset, length: argLength)
                    else { return nil }

                return body
            }
            .sorted { arg1, _ -> Bool in
                return protectedArguments.contains(arg1)
            }

        /*
         *  - Check if the number of arguments is two (otherwise there's no need to continue)
         *  - Check if the first argument is a protected word (otherwise there's no need to continue)
         *  - Get the suggestion for the given protected word (taking in consideration the presence of
         *    optionals
         */
        guard
            arguments.count == 2,
            let argument = arguments.first, protectedArguments.contains(argument),
            let hasOptional = arguments.last?.contains("?"),
            let suggestedMatcher = matcher.suggestion(for: argument, hasOptional: hasOptional)
            else { return [] }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset),
                           reason: "Prefer the specific matcher '\(suggestedMatcher)' instead.")
        ]
    }

    private let protectedArguments: Set<String> = [
        "false", "true", "nil"
    ]
}

private enum XCTestMatcher: String {
    case equal = "XCTAssertEqual"
    case notEqual = "XCTAssertNotEqual"

    func suggestion(for protectedArgument: String, hasOptional: Bool) -> String? {
        switch (self, protectedArgument, hasOptional) {
        case (.equal, "true", false): return "XCTAssertTrue"
        case (.equal, "false", false): return "XCTAssertFalse"
        case (.equal, "nil", _): return "XCTAssertNil"
        case (.notEqual, "true", false): return "XCTAssertFalse"
        case (.notEqual, "false", false): return "XCTAssertTrue"
        case (.notEqual, "nil", _): return "XCTAssertNotNil"
        default: return nil
        }
    }
}
