//
//  NotificationCenterDetachmentRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NotificationCenterDetachmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "notification_center_detachment",
        name: "Notification Center Detachment",
        description: "An object should only remove itself as an observer in `deinit`.",
        nonTriggeringExamples: [
            "class Foo { \n" +
            "   deinit {\n" +
            "       NotificationCenter.default.removeObserver(self)\n" +
            "   }\n" +
            "}\n",
            "class Foo { \n" +
            "   func bar() {\n" +
            "       NotificationCenter.default.removeObserver(otherObject)\n" +
            "   }\n" +
            "}\n"
        ],
        triggeringExamples: [
            "class Foo { \n" +
            "   func bar() {\n" +
            "       ↓NotificationCenter.default.removeObserver(self)\n" +
            "   }\n" +
            "}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .class else {
            return []
        }

        return violationOffsets(file: file, dictionary: dictionary).map { offset in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        }
    }

    func violationOffsets(file: File, dictionary: [String: SourceKitRepresentable]) -> [Int] {
        return dictionary.substructure.flatMap { subDict -> [Int] in
            guard let kindString = subDict["key.kind"] as? String,
                let kind = SwiftExpressionKind(rawValue: kindString) else {
                    return []
            }

            // complete detachment is allowed on `deinit`
            if kind == .other,
                SwiftDeclarationKind(rawValue: kindString) == .functionMethodInstance,
                subDict["key.name"] as? String == "deinit" {
                return []
            }

            if kind == .call, subDict["key.name"] as? String == "NotificationCenter.default.removeObserver",
                parameterIsSelf(dictionary: subDict, file: file),
                let offset = (subDict["key.offset"] as? Int64).flatMap({ Int($0) }) {
                return [offset]
            }

            return violationOffsets(file: file, dictionary: subDict)
        }
    }

    private func parameterIsSelf(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) else {
                return false
        }

        let range = NSRange(location: bodyOffset, length: bodyLength)
        let tokens = file.syntaxMap.tokens(inByteRange: range)
        let types = tokens.flatMap { SyntaxKind(rawValue: $0.type) }

        guard types == [.keyword], let token = tokens.first else {
            return false
        }

        let body = file.contents.bridge().substringWithByteRange(start: token.offset, length: token.length)
        return body == "self"
    }
}
