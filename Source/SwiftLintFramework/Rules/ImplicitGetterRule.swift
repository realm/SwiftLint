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

public struct ImplicitGetterRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_getter",
        name: "Implicit Getter",
        description: "Computed read-only properties and subscripts should avoid using the get keyword.",
        kind: .style,
        nonTriggeringExamples: [
            classScoped("var foo: Int {\n get {\n return 3\n}\n set {\n _abc = newValue \n}\n}"),
            classScoped("var foo: Int {\n return 20 \n} \n}"),
            classScoped("static var foo: Int {\n return 20 \n} \n}"),
            classScoped("static foo: Int {\n get {\n return 3\n}\n set {\n _abc = newValue \n}\n}"),
            classScoped("var foo: Int"),
            classScoped("var foo: Int {\n return getValueFromDisk() \n} \n}"),
            classScoped("var foo: String {\n return \"get\" \n} \n}"),
            classScoped("subscript(i: Int) -> Int {\n return 20 \n} \n}"),
            classScoped("subscript(i: Int) -> Int {\n get {\n return 3\n}\n set {\n _abc = newValue \n}\n}"),
            "protocol Foo {\n var foo: Int { get }\n",
            "protocol Foo {\n var foo: Int { get set }\n",
            "protocol Foo {\n subscript(i: Int) -> Int { get }\n",
            "protocol Foo {\n subscript(i: Int) -> Int { get set }\n",
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
            "}\n",
            "var _objCTaggedPointerBits: UInt {\n" +
            "   @inline(__always) get { return 0 }\n" +
            "}\n",
            "var next: Int? {\n" +
            "   mutating get {\n" +
            "       defer { self.count += 1 }\n" +
            "       return self.count\n" +
            "   }\n" +
            "}\n"
        ],
        triggeringExamples: [
            classScoped("var foo: Int {\n ↓get {\n return 20 \n} \n} \n}"),
            classScoped("var foo: Int {\n ↓get{\n return 20 \n} \n} \n}"),
            classScoped("static var foo: Int {\n ↓get {\n return 20 \n} \n} \n}"),
            "var foo: Int {\n ↓get {\n return 20 \n} \n} \n}",
            classScoped("@objc func bar() { }\nvar foo: Int {\n ↓get {\n return 20 \n} \n} \n}"),
            classScoped("subscript(i: Int) -> Int {\n ↓get {\n return 20 \n} \n} \n}")
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\{[^\\{]*?\\s+get\\b"
        let attributesKinds: Set<SyntaxKind> = [.attributeBuiltin, .attributeID]
        let getTokens: [SyntaxToken] = file.rangesAndTokens(matching: pattern).flatMap { _, tokens in
            let kinds = tokens.flatMap { SyntaxKind(rawValue: $0.type) }
            guard let token = tokens.last,
                SyntaxKind(rawValue: token.type) == .keyword,
                attributesKinds.intersection(kinds).isEmpty else {
                    return nil
            }

            return token
        }

        let violatingLocations = getTokens.flatMap { token -> (Int, SwiftDeclarationKind?)? in
            // the last element is the deepest structure
            guard let dict = declarations(forByteOffset: token.offset, structure: file.structure).last else {
                return nil
            }

            // If there's a setter, `get` is allowed
            guard dict.setterAccessibility == nil else {
                return nil
            }

            let kind = dict.kind.flatMap(SwiftDeclarationKind.init(rawValue:))
            return (token.offset, kind)
        }

        return violatingLocations.map { offset, kind in
            let reason = kind.map { kind -> String in
                let kind = kind == .functionSubscript ? "subscripts" : "properties"
                return "Computed read-only \(kind) should avoid using the get keyword."
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }

    private func declarations(forByteOffset byteOffset: Int,
                              structure: Structure) -> [[String: SourceKitRepresentable]] {
        var results = [[String: SourceKitRepresentable]]()
        let allowedKinds = Set(SwiftDeclarationKind.variableKinds()).subtracting([.varParameter])
                                                                    .union([.functionSubscript])

        func parse(dictionary: [String: SourceKitRepresentable], parentKind: SwiftDeclarationKind?) {

            // Only accepts declarations which contains a body and contains the
            // searched byteOffset
            guard let kindString = dictionary.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString),
                let bodyOffset = dictionary.bodyOffset,
                let bodyLength = dictionary.bodyLength,
                case let byteRange = NSRange(location: bodyOffset, length: bodyLength),
                NSLocationInRange(byteOffset, byteRange) else {
                    return
            }

            if parentKind != .protocol && allowedKinds.contains(kind) {
                results.append(dictionary)
            }

            for dictionary in dictionary.substructure {
                parse(dictionary: dictionary, parentKind: kind)
            }
        }

        for dictionary in structure.dictionary.substructure {
            parse(dictionary: dictionary, parentKind: nil)
        }

        return results
    }
}
