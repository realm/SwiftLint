//
//  NoGroupingExtensionRule.swift
//  SwiftLint
//
//  Created by Mazyad Alabduljaleel on 8/20/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NoGroupingExtensionRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_grouping_extension",
        name: "No Grouping Extension",
        description: "Extensions shouldn't be used to group code within the same source file.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "protocol Food {}\nextension Food {}\n",
            "class Apples {}\nextension Oranges {}\n"
        ],
        triggeringExamples: [
            "enum Fruit {}\n↓extension Fruit {}\n",
            "↓extension Tea: Error {}\nstruct Tea {}\n",
            "class Ham { class Spam {}}\n↓extension Ham.Spam {}\n",
            "extension External { struct Gotcha {}}\n↓extension External.Gotcha {}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {

        let elements = findAllElements(in: file.structure.dictionary,
                                       of: [.class, .enum, .struct, .extension])

        let susceptibleNames = Set(elements.flatMap { $0.kind != .extension ? $0.name : nil })

        return elements
            .filter { $0.kind == .extension && susceptibleNames.contains($0.name) }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0.offset))
            }
    }

    private func findAllElements(in dictionary: [String: SourceKitRepresentable],
                                 of types: Set<SwiftDeclarationKind>,
                                 namespace: [String] = []) -> [Element] {

        return dictionary.substructure.flatMap { subDict -> [Element] in

            var elements: [Element] = []
            guard let element = Element(dictionary: subDict, namespace: namespace) else {
                return elements
            }

            if types.contains(element.kind) {
                elements.append(element)
            }

            elements += findAllElements(in: subDict, of: types, namespace: [element.name])

            return elements
        }
    }
}

private struct Element {

    let name: String
    let kind: SwiftDeclarationKind
    let offset: Int

    init?(dictionary: [String: SourceKitRepresentable], namespace: [String]) {

        guard let name = dictionary.name,
            let kind = dictionary.kind.flatMap(SwiftDeclarationKind.init),
            let offset = dictionary.offset
            else {
                return nil
        }

        self.name = (namespace + [name]).joined(separator: ".")
        self.kind = kind
        self.offset = offset
    }
}
