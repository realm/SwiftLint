//
//  NoExtensionAccessModifier.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 04/23/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NoExtensionAccessModifierRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_extension_access_modifier",
        name: "No Extension Access Modifier",
        description: "Prefer not to use extension access modifiers",
        nonTriggeringExamples: [
            "extension String {}",
            "\n\n extension String {}"
            ],
        triggeringExamples: [
            "private extension String {}",
            "public \n extension String {}",
            "open extension String {}",
            "internal extension String {}",
            "fileprivate extension String {}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String : SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .extension, let offset = dictionary.offset else {
            return []
        }

        let syntaxTokens = file.syntaxMap.tokens
        let parts = syntaxTokens.partitioned { offset <= $0.offset }
        guard let aclToken = parts.first.last, file.isACL(token: aclToken) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func isACL(token: SyntaxToken, file: File) -> Bool {
        guard SyntaxKind(rawValue: token.type) == .attributeBuiltin else {
            return false
        }

        let contents = file.contents.bridge()
        let aclString = contents.substringWithByteRange(start: token.offset,
                                                        length: token.length)
        return aclString.flatMap(AccessControlLevel.init(description:)) != nil
    }
}
