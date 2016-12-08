//
//  RedundantStringEnumValueRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RedundantStringEnumValueRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_string_enum_value",
        name: "Redudant String Enum Value",
        description: "String enum values can be ommited when they are equal to the enumcase name.",
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

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .enum else {
            return []
        }

        // Check if it's a String enum
        let inheritedTypes = (dictionary["key.inheritedtypes"] as? [SourceKitRepresentable])?
            .flatMap({ ($0 as? [String: SourceKitRepresentable]) as? [String: String] })
            .flatMap({ $0["key.name"] }) ?? []
        guard inheritedTypes.contains("String") else {
            return []
        }

        let violations = violatingOffsetsForEnum(dictionary: dictionary, file: file)
        return violations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violatingOffsetsForEnum(dictionary: [String: SourceKitRepresentable],
                                         file: File) -> [Int] {
        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        var enumCases = 0

        let violations = substructure.flatMap { subItem -> [Int] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String,
                SwiftDeclarationKind(rawValue: kindString) == .enumcase else {
                    return []
            }

            enumCases += enumElementsCount(dictionary: subDict)
            return violatingOffsetsForEnumCase(dictionary: subDict, file: file)
        }

        guard violations.count == enumCases else {
            return []
        }

        return violations
    }

    private func enumElementsCount(dictionary: [String: SourceKitRepresentable]) -> Int {
        let enumSubstructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        return enumSubstructure.filter { item -> Bool in
            guard let subDict = item as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String,
                SwiftDeclarationKind(rawValue: kindString) == .enumelement else {
                    return false
            }

            guard !filterEnumInits(dictionary: subDict).isEmpty else {
                return false
            }

            return true
        }.count
    }

    private func violatingOffsetsForEnumCase(dictionary: [String: SourceKitRepresentable],
                                             file: File) -> [Int] {
        let enumSubstructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
        let violations = enumSubstructure.flatMap { item -> [Int] in
            guard let subDict = item as? [String: SourceKitRepresentable],
                let kindString = subDict["key.kind"] as? String,
                SwiftDeclarationKind(rawValue: kindString) == .enumelement,
                let name = subDict["key.name"] as? String else {
                    return []
            }

            return violatingOffsetsForEnumElement(dictionary: subDict, name: name, file: file)
        }

        return violations
    }

    private func violatingOffsetsForEnumElement(dictionary: [String: SourceKitRepresentable],
                                                name: String,
                                                file: File) -> [Int] {
        let enumInits = filterEnumInits(dictionary: dictionary)

        return enumInits.flatMap { dictionary -> Int? in
            guard let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
                let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }) else {
                    return nil
            }

            // the string would be quoted if offset and length were used directly
            let enumCaseName = file.contents.substringWithByteRange(start: offset + 1,
                                                                    length: length - 2) ?? ""
            guard enumCaseName == name else {
                return nil
            }

            return offset
        }
    }

    private func filterEnumInits(dictionary: [String: SourceKitRepresentable]) ->
                                                                [[String: SourceKitRepresentable]] {
        guard let elements = dictionary["key.elements"] as? [SourceKitRepresentable] else {
            return []
        }

        let enumInitKind = "source.lang.swift.structure.elem.init_expr"
        return elements.flatMap { element in
            guard let dict = element as? [String: SourceKitRepresentable],
                dict["key.kind"] as? String == enumInitKind else {
                    return nil
            }

            return dict
        }
    }
}
