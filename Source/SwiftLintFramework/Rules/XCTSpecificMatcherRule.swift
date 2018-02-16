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
         *  word is the first one (if any).
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
            .flatMap { argument -> String? in
                guard
                    let argOffset = argument.bodyOffset,
                    let argBodyLength = argument.bodyLength,
                    let body = file.contents.bridge().substringWithByteRange(start: argOffset, length: argBodyLength)
                    else { return nil }

                return body
            }
            .sorted { arg1, _ -> Bool in
                return protectedArguments.contains(arg1)
            }

        /*
         *  - Check if the first one is a protected word, otherwise there's not need to continue.
         *  - Retrieve the suggestion for the protected word, making sure that optional arguments are considered.
         *
         *  Note that optional arguments don't show on dictionary.substructure, therefore arguments.count == 1 implies
         *  it contains an optional argument.
         */
        guard
            let argument = arguments.first, protectedArguments.contains(argument),
            let suggestedMatcher = matcher.suggestion(for: argument, containsOptionalArgument: arguments.count == 1)
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

    func suggestion(for protectedArgument: String, containsOptionalArgument: Bool) -> String? {
        switch (self, protectedArgument, containsOptionalArgument) {
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
