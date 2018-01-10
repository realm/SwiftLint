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

        // Checks the first two arguments looking for 'true', 'false', and 'nil'.
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
                    let body = file.contents.bridge().substringWithByteRange(start: argOffset, length: argBodyLength),
                    protectedArguments.contains(body) else { return nil }

                return body
            }

        // If the call has "protected" arguments, provides suggestion based on the first one.
        guard
            let argument = arguments.first,
            let suggestedMatcher = matcher.suggestion(for: argument) else { return [] }

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

    func suggestion(for argument: String) -> String? {
        switch (self, argument) {
        case (.equal, "true"): return "XCTAssertTrue"
        case (.equal, "false"): return "XCTAssertFalse"
        case (.equal, "nil"): return "XCTAssertNil"
        case (.notEqual, "true"): return "XCTAssertFalse"
        case (.notEqual, "false"): return "XCTAssertTrue"
        case (.notEqual, "nil"): return "XCTAssertNotNil"
        default: return nil
        }
    }
}
