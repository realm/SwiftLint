//
//  ValidIBInspectableRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ValidIBInspectableRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)
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
            "class Foo {\n  @IBInspectable private var count: Int = 0\n}\n",
            "class Foo {\n  private var notInspectable = 0\n}\n",
            "class Foo {\n  private let notInspectable: Int\n}\n",
            "class Foo {\n  private let notInspectable: UInt8\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  @IBInspectable private ↓let count: Int\n}\n",
            "class Foo {\n  @IBInspectable private ↓var insets: UIEdgeInsets\n}\n",
            "class Foo {\n  @IBInspectable private ↓var count = 0\n}\n",
            "class Foo {\n  @IBInspectable private ↓var count: Int?\n}\n",
            "class Foo {\n  @IBInspectable private ↓var count: Int!\n}\n",
            "class Foo {\n  @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<Int>\n}\n",
            "class Foo {\n  @IBInspectable private ↓var count: Optional<Int>\n}\n",
            "class Foo {\n  @IBInspectable private ↓var x: Optional<String>\n}\n",
            "class Foo {\n  @IBInspectable private ↓var x: ImplicitlyUnwrappedOptional<String>\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance else {
            return []
        }

        // Check if IBInspectable
        let isIBInspectable = dictionary.enclosedSwiftAttributes.contains(
           "source.decl.attribute.ibinspectable")
        guard isIBInspectable else {
            return []
        }

        let shouldMakeViolation: Bool
        if dictionary.setterAccessibility == nil {
            // if key.setter_accessibility is nil, it's a `let` declaration
            shouldMakeViolation = true
        } else if let type = dictionary.typeName,
            ValidIBInspectableRule.supportedTypes.contains(type) {
            shouldMakeViolation = false
        } else {
            // Variable should have explicit type or IB won't recognize it
            // Variable should be of one of the supported types
            shouldMakeViolation = true
        }

        guard shouldMakeViolation else {
            return []
        }

        let location: Location
        if let offset = dictionary.offset {
            location = Location(file: file, byteOffset: offset)
        } else {
            location = Location(file: file.path)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: location)
        ]
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
            "NSImage"
        ]

        let types = [
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

        let intTypes = ["", "8", "16", "32", "64"].flatMap { size in
            ["U", ""].flatMap { (sign: String) -> String in
                "\(sign)Int\(size)"
            }
        }

        let expandToIncludeOptionals: (String) -> [String] = { [$0, $0 + "!", $0 + "?"] }

        // It seems that only reference types can be used as ImplicitlyUnwrappedOptional or Optional
        return referenceTypes.flatMap(expandToIncludeOptionals) + types + intTypes
    }
}
