//
//  ValidIBInspectableRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/20/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ValidIBInspectableRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Warning)
    private static let supportedTypes = ValidIBInspectableRule.createSupportedTypes()

    public init() {}

    public static let description = RuleDescription(
        identifier: "valid_ibinspectable",
        name: "Valid IBInspectable",
        description: "@IBInspectable should be applied to variables only, have its type explicit " +
        "and be of a supported type",
        nonTriggeringExamples: [
            "class Foo {\n  @IBInspectable private var x: Int\n}\n",
            "class Foo {\n  @IBInspectable private var x: String?\n}\n",
            "class Foo {\n  @IBInspectable private var x: String!\n}\n",
            "class Foo {\n  @IBInspectable private var x: ImplicitlyUnwrappedOptional<String>\n}\n",
            "class Foo {\n  @IBInspectable private var x: Optional<String>\n}\n",
            "class Foo {\n  @IBInspectable private var count: Int = 0\n}\n",
            "class Foo {\n  private var notInspectable = 0\n}\n",
            "class Foo {\n  private let notInspectable: Int\n}\n",
        ],
        triggeringExamples: [
            "class Foo {\n  @IBInspectable private let count: Int\n}\n",
            "class Foo {\n  @IBInspectable private var insets: UIEdgeInsets\n}\n",
            "class Foo {\n  @IBInspectable private var count = 0\n}\n",
            "class Foo {\n  @IBInspectable private var count: Int?\n}\n",
            "class Foo {\n  @IBInspectable private var count: Int!\n}\n",
            "class Foo {\n  @IBInspectable private var x: ImplicitlyUnwrappedOptional<Int>\n}\n",
            "class Foo {\n  @IBInspectable private var count: Optional<Int>\n}\n",
        ]
    )

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == .VarInstance else {
            return []
        }

        // Check if IBInspectable
        let attributes = (dictionary["key.attributes"] as? [SourceKitRepresentable])?
            .flatMap({ ($0 as? [String: SourceKitRepresentable]) as? [String: String] })
            .flatMap({ $0["key.attribute"] }) ?? []
        let isIBInspectable = attributes.contains("source.decl.attribute.ibinspectable")
        guard isIBInspectable else {
            return []
        }

        // if key.setter_accessibility is nil, it's a `let` declaration
        if dictionary["key.setter_accessibility"] == nil {
            return violation(dictionary, file: file)
        }

        // Variable should have explicit type or IB won't recognize it
        // Variable should be of one of the supported types
        guard let type = dictionary["key.typename"] as? String
            where ValidIBInspectableRule.supportedTypes.contains(type) else {
                return violation(dictionary, file: file)
        }

        return []
    }

    private static func createSupportedTypes() -> [String] {
        // "You can add the IBInspectable attribute to any property in a class declaration,
        // class extension, or category of type: boolean, integer or floating point number, string,
        // localized string, rectangle, point, size, color, range, and nil."
        //
        // from http://help.apple.com/xcode/mac/8.0/#/devf60c1c514

        let referenceTypes = [
            "String",
            "NSString",
            "UIColor",
            "NSColor",
            "UIImage",
            "NSImage",
            "NSNumber"
        ]

        let types = [
            "Int",
            "CGFloat",
            "Float",
            "Double",
            "Bool",
            "CGPoint",
            "NSPoint",
            "CGSize",
            "NSSize",
            "CGRect",
            "NSRect"
        ]

        // It seems that only reference types can be used as ImplicitlyUnwrappedOptional or Optional
        return referenceTypes.flatMap {
            [$0, $0 + "!", $0 + "?",
            "ImplicitlyUnwrappedOptional<\($0)>", "Optional<\($0)>"] + types
        }
    }

    private func violation(dictionary: [String: SourceKitRepresentable],
                           file: File) -> [StyleViolation] {

        let location: Location
        if let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: location
            )
        ]
    }
}
