//
//  NoExtensionAccessModifier.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 04/23/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NoExtensionAccessModifierRule: OptInRule, ConfigurationProviderRule {
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

    public func validate(file: File) -> [StyleViolation] {
        let extensions = file.structure.dictionary.substructure.flatMap({ element -> Int? in
            guard let kind = element.kind, kind == "source.lang.swift.decl.extension",
                let offset = element.offset else { return nil }
            return offset
        })
        let syntaxTokens = file.syntaxMap.tokens
            let violations = extensions.flatMap { (offSet) -> Int? in
                let parts = syntaxTokens.partitioned { offSet <= $0.offset }
                guard let lastKind = parts.first.last else { return nil }
                return lastKind.type == SyntaxKind.attributeBuiltin.rawValue ? offSet : nil
            }

        return violations.map({
            StyleViolation(
                ruleDescription: NoExtensionAccessModifierRule.description,
                location: Location(file: file, byteOffset: $0))
        })
    }
}
