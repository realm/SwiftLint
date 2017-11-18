//
//  OverrideInExtensionRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 10/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct OverrideInExtensionRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "override_in_extension",
        name: "Override in Extension",
        description: "Extensions shouldn't override declarations.",
        kind: .lint,
        nonTriggeringExamples: [
            "extension Person {\n  var age: Int { return 42 }\n}\n",
            "extension Person {\n  func celebrateBirthday() {}\n}\n",
            "class Employee: Person {\n  override func celebrateBirthday() {}\n}\n",
            "class Foo: NSObject {}\n" +
            "extension Foo {\n" +
            "    override var description: String { return \"\" }\n" +
            "}\n",
            "struct Foo {\n" +
            "    class Bar: NSObject {}\n" +
            "}\n" +
            "extension Foo.Bar {\n" +
            "    override var description: String { return \"\" }\n" +
            "}\n"
        ],
        triggeringExamples: [
            "extension Person {\n  override ↓var age: Int { return 42 }\n}\n",
            "extension Person {\n  override ↓func celebrateBirthday() {}\n}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let collector = NamespaceCollector(dictionary: file.structure.dictionary)
        let elements = collector.findAllElements(of: [.class, .struct, .enum, .extension])

        let susceptibleNames = Set(elements.flatMap { $0.kind == .class ? $0.name : nil })

        return elements
            .filter { $0.kind == .extension && !susceptibleNames.contains($0.name) }
            .flatMap { element in
                return element.dictionary.substructure.flatMap { element -> Int? in
                    guard element.kind.flatMap(SwiftDeclarationKind.init) != nil,
                        element.enclosedSwiftAttributes.contains("source.decl.attribute.override"),
                        let offset = element.offset else {
                            return nil
                    }

                    return offset
                }
            }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: $0))
            }
    }
}
