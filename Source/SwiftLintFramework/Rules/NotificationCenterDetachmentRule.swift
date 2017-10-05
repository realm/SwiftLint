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
        kind: .lint,
        nonTriggeringExamples: NotificationCenterDetachmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: NotificationCenterDetachmentRuleExamples.triggeringExamples
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

    private func violationOffsets(file: File,
                                  dictionary: [String: SourceKitRepresentable]) -> [Int] {
        return dictionary.substructure.flatMap { subDict -> [Int] in
            // complete detachment is allowed on `deinit`
            if subDict.kind.flatMap(SwiftDeclarationKind.init) == .functionMethodInstance,
                subDict.name == "deinit" {
                return []
            }

            if subDict.kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .call,
                subDict.name == methodName,
                parameterIsSelf(dictionary: subDict, file: file),
                let offset = subDict.offset {
                return [offset]
            }

            return violationOffsets(file: file, dictionary: subDict)
        }
    }

    private var methodName = "NotificationCenter.default.removeObserver"

    private func parameterIsSelf(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength else {
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
