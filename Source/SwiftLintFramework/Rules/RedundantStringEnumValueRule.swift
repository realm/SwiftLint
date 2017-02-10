//
//  RedundantStringEnumValueRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private func children(of dict: [String: SourceKitRepresentable],
                      matching kind: SwiftDeclarationKind) -> [[String: SourceKitRepresentable]] {
    return dict.substructure.flatMap { subDict in
        if let kindString = subDict.kind,
            SwiftDeclarationKind(rawValue: kindString) == kind {
            return subDict
        }
        return nil
    }
}

public struct RedundantStringEnumValueRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_string_enum_value",
        name: "Redundant String Enum Value",
        description: "String enum values can be omitted when they are equal to the enumcase name.",
        nonTriggeringExamples: [
            "enum Numbers: String {\n case one\n case two\n}\n",
            "enum Numbers: Int {\n case one = 1\n case two = 2\n}\n",
            "enum Numbers: String {\n case one = \"ONE\"\n case two = \"TWO\"\n}\n",
            "enum Numbers: String {\n case one = \"ONE\"\n case two = \"two\"\n}\n",
            "enum Numbers: String {\n case one, two\n}\n"
        ],
        triggeringExamples: [
            "enum Numbers: String {\n case one = ↓\"one\"\n case two = ↓\"two\"\n}\n",
            "enum Numbers: String {\n case one = ↓\"one\", two = ↓\"two\"\n}\n",
            "enum Numbers: String {\n case one, two = ↓\"two\"\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        // Check if it's a String enum
        guard dictionary.inheritedTypes.contains("String") else {
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
        var caseCount = 0
        var violations = [Int]()

        for enumCase in children(of: dictionary, matching: .enumcase) {
            caseCount += enumElementsCount(dictionary: enumCase)
            violations += violatingOffsetsForEnumCase(dictionary: enumCase, file: file)
        }

        guard violations.count == caseCount else {
            return []
        }

        return violations
    }

    private func enumElementsCount(dictionary: [String: SourceKitRepresentable]) -> Int {
        return children(of: dictionary, matching: .enumelement).filter({ element in
            return !filterEnumInits(dictionary: element).isEmpty
        }).count
    }

    private func violatingOffsetsForEnumCase(dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {
        return children(of: dictionary, matching: .enumelement).flatMap { element -> [Int] in
            guard let name = element.name else {
                return []
            }
            return violatingOffsetsForEnumElement(dictionary: element, name: name, file: file)
        }
    }

    private func violatingOffsetsForEnumElement(dictionary: [String: SourceKitRepresentable], name: String,
                                                file: File) -> [Int] {
        let enumInits = filterEnumInits(dictionary: dictionary)

        return enumInits.flatMap { dictionary -> Int? in
            guard let offset = dictionary.offset,
                let length = dictionary.length else {
                    return nil
            }

            // the string would be quoted if offset and length were used directly
            let enumCaseName = file.contents.bridge()
                .substringWithByteRange(start: offset + 1, length: length - 2) ?? ""
            guard enumCaseName == name else {
                return nil
            }

            return offset
        }
    }

    private func filterEnumInits(dictionary: [String: SourceKitRepresentable]) -> [[String: SourceKitRepresentable]] {
        return dictionary.elements.filter {
            $0.kind == "source.lang.swift.structure.elem.init_expr"
        }
    }
}
