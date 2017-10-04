//
//  DiscardedNotificationCenterObserverRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/13/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DiscardedNotificationCenterObserverRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discarded_notification_center_observer",
        name: "Discarded Notification Center Observer",
        description: "When registering for a notification using a block, the opaque observer that is " +
                     "returned should be stored so it can be removed later.",
        kind: .lint,
        nonTriggeringExamples: [
            "let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n",
            "let foo = nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n",
            "func foo() -> Any {\n" +
            "   return nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n"
        ],
        triggeringExamples: [
            "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil) { }\n",
            "↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n",
            "@discardableResult func foo() -> Any {\n" +
            "   return ↓nc.addObserver(forName: .NSSystemTimeZoneDidChange, object: nil, queue: nil, using: { })\n" +
            "}\n"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationOffsets(in: file, dictionary: dictionary, kind: kind).map { location in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: location))
        }
    }

    private func violationOffsets(in file: File, dictionary: [String: SourceKitRepresentable],
                                  kind: SwiftExpressionKind) -> [Int] {
        guard kind == .call,
            let name = dictionary.name,
            name.hasSuffix(".addObserver"),
            case let arguments = dictionary.enclosedArguments,
            case let argumentsNames = arguments.flatMap({ $0.name }),
            argumentsNames == ["forName", "object", "queue"] ||
                argumentsNames == ["forName", "object", "queue", "using"],
            let offset = dictionary.offset,
            let range = file.contents.bridge().byteRangeToNSRange(start: 0, length: offset) else {
                return []
        }

        if let lastMatch = regex("\\s?=\\s*").matches(in: file.contents, options: [], range: range).last?.range,
            lastMatch.location == range.length - lastMatch.length {
            return []
        }

        if let lastMatch = file.match(pattern: "\\breturn\\s+", with: [.keyword], range: range).last,
            lastMatch.location == range.length - lastMatch.length,
            let lastFunction = file.structure.functions(forByteOffset: offset).last,
            !lastFunction.enclosedSwiftAttributes.contains("source.decl.attribute.discardableResult") {
            return []
        }

        return [offset]
    }
}

private extension Structure {
    func functions(forByteOffset byteOffset: Int) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()

        func parse(_ dictionary: [String: SourceKitRepresentable]) {
            guard let offset = dictionary.offset,
                let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }),
                NSLocationInRange(byteOffset, byteRange) else {
                    return
            }

            if let kind = dictionary.kind.flatMap(SwiftDeclarationKind.init),
                SwiftDeclarationKind.functionKinds.contains(kind) {
                results.append(dictionary)
            }
            dictionary.substructure.forEach(parse)
        }
        parse(dictionary)
        return results
    }
}
