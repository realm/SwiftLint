//
//  ImplicitGetterRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 29/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func classScoped(_ value: String) -> String {
    return "class Foo {\n  \(value)\n}\n"
}

public struct ImplicitGetterRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

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
            "protocol Foo {\n var foo: Int { get set }\n",
            "class Foo {\n" +
            "  var foo: Int {\n" +
            "    struct Bar {\n" +
            "      var bar: Int {\n" +
            "        get { return 1 }\n" +
            "        set { _ = newValue }\n" +
            "      }\n" +
            "    }\n" +
            "    return Bar().bar\n" +
            "  }\n" +
            "}\n"
        ],
        triggeringExamples: [
            classScoped("var foo: Int {\n ↓get {\n return 20 \n} \n} \n}"),
            classScoped("static var foo: Int {\n ↓get {\n return 20 \n} \n} \n}")
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let getTokens = file.syntaxMap.tokens.filter { token -> Bool in
            guard SyntaxKind(rawValue: token.type) == .keyword else {
                return false
            }

            guard let tokenValue = file.contents.substringWithByteRange(start: token.offset,
                length: token.length) else {
                    return false
            }

            return tokenValue == "get"
        }

        let violatingTokens = getTokens.filter { token -> Bool in
            // the last element is the deepest structure
            guard let dictionary =
                variableDeclarationsFor(token.offset, structure: file.structure).last else {
                    return false
            }

            // If there's a setter, `get` is allowed
            return dictionary["key.setter_accessibility"] == nil
        }

        return violatingTokens.map { token in
            // Violation found!
            let location = Location(file: file, byteOffset: token.offset)

            return StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location
            )
        }
    }

    private func variableDeclarationsFor(_ byteOffset: Int, structure: Structure) ->
                                                          [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()

        func parse(dictionary: [String: SourceKitRepresentable]) {

            let allowedKinds: [SwiftDeclarationKind] = [.varClass, .varInstance, .varStatic]

            // Only accepts variable declarations which contains a body and contains the
            // searched byteOffset
            if let kindString = (dictionary["key.kind"] as? String),
                let kind = SwiftDeclarationKind(rawValue: kindString),
                let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
                let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
                allowedKinds.contains(kind) {
                let byteRange = NSRange(location: bodyOffset, length: bodyLength)

                if NSLocationInRange(byteOffset, byteRange) {
                    results.append(dictionary)
                }
            }

            let typeKinds: [SwiftDeclarationKind] = [
                .class,
                .enum,
                .extension,
                .extensionClass,
                .extensionEnum,
                .extensionProtocol,
                .extensionStruct,
                .struct
            ] + allowedKinds

            if let subStructure = dictionary["key.substructure"] as? [SourceKitRepresentable] {
                for case let dictionary as [String: SourceKitRepresentable] in subStructure {
                    if let kindString = (dictionary["key.kind"] as? String),
                        let kind = SwiftDeclarationKind(rawValue: kindString),
                        typeKinds.contains(kind) {
                        parse(dictionary: dictionary)
                    }
                }
            }
        }
        parse(dictionary: structure.dictionary)
        return results
    }
}
