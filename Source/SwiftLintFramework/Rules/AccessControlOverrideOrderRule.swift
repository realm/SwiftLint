//
//  AccessControlOverrideOrderRule.swift
//  SwiftLint
//
//  Created by Daniel.Metzing on 12/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct AccessControlOverrideOrderRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "access_control_override_order",
        name: "Access Control Override Order",
        description: "Access control property keywords should be followed by the override keyword.",
        kind: .lint,
        nonTriggeringExamples: [
            "public override init()\n",
            "internal override init()\n",
            "private override init(){}\n",
            "open override var foo: String\n",
            "public override var foo: String\n",
            "internal override var foo: String\n",
            "private override var foo: String\n",
            "open override func foo() -> String",
            "public override func foo() -> String",
            "internal override func foo() -> String",
            "private override func foo() -> String"
        ],
        triggeringExamples: [
            "↓override public init()\n",
            "↓override internal init()\n",
            "↓override private init(){}\n",
            "↓override open var foo: String\n",
            "↓override public var foo: String\n",
            "↓override internal var foo: String\n",
            "↓override private var foo: String\n",
            "↓override open func foo() -> String",
            "↓override public func foo() -> String",
            "↓override internal func foo() -> String",
            "↓override private func foo() -> String"
        ])

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            isOverride(attributes: dictionary.enclosedSwiftAttributes),
            let accessControlLevel = dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)),
            let keyOffset = dictionary.offset,
            let syntaxTokens = syntaxTokens(at: keyOffset, in: file) else {
                return []
        }

        let attributeTokens = syntaxTokens.filter { $0.type == SyntaxKind.attributeBuiltin.rawValue }
        let contents = textContents(of: attributeTokens, in: file)

        if let accessIndex = contents.index(of: accessControlLevel.description),
           let overrideIndex = contents.index(of: "override"),
           accessIndex > overrideIndex {
                let offSet = safeOffSet(of: attributeTokens[overrideIndex], in: file)
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: .error,
                                       location: Location(file: file, characterOffset: offSet),
                                       reason: configuration.consoleDescription)]
        }

        return []
    }

    private func isOverride(attributes: [String]) -> Bool {
        return attributes.contains("source.decl.attribute.override")
    }

    private func syntaxTokens(at keywordOffset: Int, in file: File) -> [SyntaxToken]? {
        return file
            .syntaxTokensByLine()
            .flatMap { $0.first { $0.contains { $0.offset == keywordOffset } } }
    }

    private func textContents(of attributeTokens: [SyntaxToken], in file: File) -> [String] {
        return attributeTokens.flatMap {
            file.contents.bridge().substringWithByteRange(start: $0.offset, length: $0.length)
        }
    }

    private func safeOffSet(of token: SyntaxToken, in file: File) -> Int {
        let start = token.offset
        let length = token.length
        let convertedRange = file.contents.bridge().byteRangeToNSRange(start: start, length: length)
        return convertedRange?.location ?? 0
    }
}
