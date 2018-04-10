//
//  MultipleClosuresWithTrailingClosureRule.swift
//  SwiftLint
//
//  Created by Erik Strottmann on 8/26/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultipleClosuresWithTrailingClosureRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiple_closures_with_trailing_closure",
        name: "Multiple Closures with Trailing Closure",
        description: "Trailing closure syntax should not be used when passing more than one closure argument.",
        kind: .style,
        nonTriggeringExamples: [
            "foo.map { $0 + 1 }\n",
            "foo.reduce(0) { $0 + $1 }\n",
            "if let foo = bar.map({ $0 + 1 }) {\n\n}\n",
            "foo.something(param1: { $0 }, param2: { $0 + 1 })\n",
            "UIView.animate(withDuration: 1.0) {\n" +
            "    someView.alpha = 0.0\n" +
            "}"
        ],
        triggeringExamples: [
            "foo.something(param1: { $0 }) ↓{ $0 + 1 }",
            "UIView.animate(withDuration: 1.0, animations: {\n" +
            "    someView.alpha = 0.0\n" +
            "}) ↓{ _ in\n" +
            "    someView.removeFromSuperview()\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let call = Call(file: file, kind: kind, dictionary: dictionary), call.hasTrailingClosure else {
            return []
        }

        let closureArguments = call.closureArguments
        guard closureArguments.count > 1, let trailingClosureOffset = closureArguments.last?.offset else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: trailingClosureOffset))
        ]
    }
}

private struct Call {
    let file: File
    let dictionary: [String: SourceKitRepresentable]
    let offset: Int

    init?(file: File, kind: SwiftExpressionKind, dictionary: [String: SourceKitRepresentable]) {
        guard kind == .call, let offset = dictionary.offset else {
            return nil
        }
        self.file = file
        self.dictionary = dictionary
        self.offset = offset
    }

    var hasTrailingClosure: Bool {
        guard let length = dictionary.length,
            let text = file.contents.bridge().substringWithByteRange(start: offset, length: length)
            else {
                return false
        }

        return !text.hasSuffix(")")
    }

    var closureArguments: [[String: SourceKitRepresentable]] {
        return dictionary.enclosedArguments.filter { argument in
            guard let offset = argument.bodyOffset,
                let length = argument.bodyLength,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
                let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
                match.location == range.location else {
                    return false
            }

            return true
        }
    }
}
