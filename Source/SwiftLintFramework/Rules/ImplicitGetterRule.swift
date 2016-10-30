//
//  ImplicitGetterRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func classScoped(value: String) -> String {
    return "class Foo {\n  \(value)\n}\n"
}

public struct ImplicitGetterRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties should avoid using the get keyword.",
        nonTriggeringExamples: [
            classScoped("var foo: Int {\n get {\n return 3\n}\n set {\n _abc = newValue \n}\n}"),
            classScoped("var foo: Int {\n return 20 \n} \n}"),
            classScoped("static var foo: Int {\n return 20 \n} \n}"),
            classScoped("static foo: Int {\n get {\n return 3\n}\n set {\n _abc = newValue \n}\n}"),
            classScoped("var foo: Int"),
            classScoped("var foo: Int {\n return getValueFromDisk() \n} \n}"),
            classScoped("var foo: String {\n return \"get\" \n} \n}"),
            "protocol Foo {\n var foo: Int { get }\n",
            "protocol Foo {\n var foo: Int { get set }\n"
        ],
        triggeringExamples: [
            classScoped("var foo: Int {\n ↓get {\n return 20 \n} \n} \n}"),
            classScoped("static var foo: Int {\n ↓get {\n return 20 \n} \n} \n}")
        ]
    )

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Enum,
            .Extension,
            .ExtensionClass,
            .ExtensionEnum,
            .ExtensionProtocol,
            .ExtensionStruct,
            .Struct
        ]

        guard typeKinds.contains(kind) else {
            return []
        }

        guard let substructures = (dictionary["key.substructure"] as? [SourceKitRepresentable])?
            .flatMap({ $0 as? [String: SourceKitRepresentable] }) else {
                return []
        }

        return substructures.flatMap { dictionary -> [StyleViolation] in
            guard let kind = (dictionary["key.kind"] as? String).flatMap(KindType.init) else {
                return []
            }

            return validateType(file, kind: kind, dictionary: dictionary)
        }
    }

    private func validateType(file: File,
                              kind: SwiftDeclarationKind,
                              dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let allowedKinds: [SwiftDeclarationKind] = [.VarClass, .VarInstance, .VarStatic]
        guard allowedKinds.contains(kind) else {
            return []
        }

        // If there's a setter, `get` is allowed
        guard dictionary["key.setter_accessibility"] == nil else {
            return []
        }

        // Only validates properties with body
        guard let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }) else {
                return []
        }

        let bodyRange = NSRange(location: bodyOffset, length: bodyLength)
        let contents = (file.contents as NSString)

        let tokens = file.syntaxMap.tokensIn(bodyRange).filter { token in
            guard SyntaxKind(rawValue: token.type) == .Keyword else {
                return false
            }

            guard let tokenValue = contents.substringWithByteRange(start: token.offset,
                                                                   length: token.length) else {
                return false
            }

            return tokenValue == "get"
        }

        return tokens.map { token in
            // Violation found!
            let location = Location(file: file, byteOffset: token.offset)

            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: location
            )
        }
    }
}
