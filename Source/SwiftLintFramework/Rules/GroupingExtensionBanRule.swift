//
//  GroupingExtensionBanRule.swift
//  SwiftLint
//
//  Created by Mazyad Alabduljaleel on 8/20/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct GroupingExtensionBanRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "grouping_extension_ban",
        name: "Grouping Extension Ban",
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
                                       ofTypes: [.class, .enum, .struct, .extension])

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
                                 ofTypes types: [SwiftDeclarationKind],
                                 namespace: [String] = []) -> [Element] {

        return dictionary.substructure.flatMap { subDict -> [Element] in

            var elements: [Element] = []
            guard let element = Element(dictionary: subDict, namespace: namespace) else {
                return elements
            }

            if types.contains(element.kind) {
                elements.append(element)
            }

            elements += findAllElements(in: subDict, ofTypes: types, namespace: [element.name])

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
