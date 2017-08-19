//
//  ExplicitAssociatedEnumValueRule.swift
//  SwiftLint
//
//  Created by Mazyad Alabduljaleel on 8/19/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitAssociatedEnumValueRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_associated_enum_value",
        name: "Explicit Associated Enum Value",
        description: "Enums should be explicitly assigned their associated values.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "enum Numbers {\n case int(Int)\n case short(Int16)\n}\n",
            "enum Numbers: Int {\n case one = 1\n case two = 2\n}\n",
            "enum Numbers: Double {\n case one = 1.1\n case two = 2.2\n}\n",
            "enum Numbers: String {\n case one = \"one\"\n case two = \"two\"\n}\n",
            "enum Numbers: String {\n case one = \"ONE\"\n case two = \"TWO\"\n}\n"
        ],
        triggeringExamples: [
            "enum Numbers: Int {\n case one = 10, ↓two, three = 30\n}\n",
            "enum Numbers: String {\n case ↓one\n case ↓two\n}\n",
            "enum Numbers: String {\n case ↓one, two = \"two\"\n}\n",
            "enum Numbers: String {\n case ↓one, ↓two\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        // Check if it's an associated value enum
        guard !dictionary.inheritedTypes.isEmpty else {
            return []
        }

        let violations = violatingOffsetsForEnum(dictionary: dictionary, file: file)
        return violations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {

        let locs = substructureElements(of: dictionary, matching: .enumcase)
            .flatMap { substructureElements(of: $0, matching: .enumelement) }
            .flatMap(enumElementsMissingInitExpr)
            .flatMap { $0.offset }

        return locs
    }

    private func substructureElements(of dict: [String: SourceKitRepresentable],
                                      matching kind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {
        return dict.substructure
            .filter { $0.kind.flatMap(SwiftDeclarationKind.init) == kind }
    }

    private func enumElementsMissingInitExpr(
        _ enumElements: [[String: SourceKitRepresentable]]) -> [[String: SourceKitRepresentable]] {

        return enumElements
            .filter { !$0.elements.contains { $0.kind == "source.lang.swift.structure.elem.init_expr" } }
    }
}
