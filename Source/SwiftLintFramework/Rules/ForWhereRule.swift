//
//  ForWhereRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/29/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ForWhereRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "for_where",
        name: "For Where",
        description: "`where` clauses are preferred over a single `if` inside a `for`.",
        nonTriggeringExamples: [
            "for user in users where user.id == 1 { }\n",
            // if let
            "for user in users {\n" +
            "   if let id = user.id { }\n" +
            "}\n",
            // if with else
            "for user in users {\n" +
            "   if user.id == 1 { } else { }\n" +
            "}\n",
            // if with else if
            "for user in users {\n" +
            "   if user.id == 1 {\n" +
            "} else if user.id == 2 { }\n" +
            "}\n",
            // if is not the only expression inside for
            "for user in users {\n" +
            "   if user.id == 1 { }\n" +
            "   print(user)\n" +
            "}\n"
        ],
        triggeringExamples: [
            "for user in users {\n" +
            "   ↓if user.id == 1 { }\n" +
            "}\n"
        ]
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == .forEach,
            let subDictionary = forBody(dictionary: dictionary),
            subDictionary.substructure.count == 1,
            let bodyDictionary = subDictionary.substructure.first,
            bodyDictionary.kind.flatMap(StatementKind.init) == .if,
            isOnlyOneIf(dictionary: bodyDictionary),
            !containsLetInCondition(dictionary: bodyDictionary, file: file),
            let offset = bodyDictionary .offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func forBody(dictionary: [String: SourceKitRepresentable]) -> [String : SourceKitRepresentable]? {
        return dictionary.substructure.first(where: { subDict -> Bool in
            subDict.kind.flatMap(StatementKind.init) == .brace
        })
    }

    private func isOnlyOneIf(dictionary: [String: SourceKitRepresentable]) -> Bool {
        let substructure = dictionary.substructure
        guard substructure.count == 1 else {
            return false
        }

        return dictionary.substructure.first?.kind.flatMap(StatementKind.init) == .brace
    }

    private func containsLetInCondition(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        let kind = "source.lang.swift.structure.elem.condition_expr"
        let contents = file.contents.bridge()
        return !dictionary.elements.filter { element in
            guard element.kind == kind,
                let offset = element.offset,
                let length = element.length,
                let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return false
            }

            return !file.match(pattern: "\\blet\\b", with: [.keyword], range: range).isEmpty
        }.isEmpty
    }

}
