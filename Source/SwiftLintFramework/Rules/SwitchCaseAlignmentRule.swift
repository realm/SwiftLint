//
//  SwitchCaseAlignmentRule.swift
//  SwiftLint
//
//  Created by Austin Lu on 9/6/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SwitchCaseAlignmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "switch_case_alignment",
        name: "Switch and Case Statement Alignment",
        description: "Case statements should vertically align with the enclosing switch statement.",
        kind: .style,
        nonTriggeringExamples: [
            "switch someBool {\n" +
            "case true: // case 1\n" +
            "    print('red')\n" +
            "case false:\n" +
            "    /*\n" +
            "    case 2\n" +
            "    */\n" +
            "    if case let .someEnum(val) = someFunc() {\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}\n" +
            "enum SomeEnum {\n" +
            "    case innocent\n" +
            "}",
            "if aBool {\n" +
            "    switch someBool {\n" +
            "    case true:\n" +
            "        print('red')\n" +
            "    case false:\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}",
            "switch someInt {\n" +
            "// comments ignored\n" +
            "case 0:\n" +
            "    // zero case\n" +
            "    print('Zero')\n" +
            "case 1:\n" +
            "    print('One')\n" +
            "default:\n" +
            "    print('Some other number')\n" +
            "}"
        ],
        triggeringExamples: [
            "switch someBool {\n" +
            "    ↓case true:\n" +
            "         print('red')\n" +
            "    ↓case false:\n" +
            "         print('blue')\n" +
            "}",
            "if aBool {\n" +
            "    switch someBool {\n" +
            "        ↓case true:\n" +
            "            print('red')\n" +
            "    case false:\n" +
            "        print('blue')\n" +
            "    }\n" +
            "}",
            "switch someInt {\n" +
            "    ↓case 0:\n" +
            "    print('Zero')\n" +
            "case 1:\n" +
            "    print('One')\n" +
            "    ↓default:\n" +
            "    print('Some other number')\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()
        guard kind == .switch,
            let offset = dictionary.offset,
            let (_, switchCharacter) = contents.lineAndCharacter(forByteOffset: offset) else {
                return []
        }

        let caseStatements = dictionary.substructure.filter { subDict in
            // includes both `case` and `default` statements
            return subDict.kind.flatMap(StatementKind.init) == .case
        }

        if caseStatements.isEmpty {
            return []
        }

        let caseLocations = caseStatements.flatMap { caseDict -> Location? in
            guard let byteOffset = caseDict.offset,
                let (line, char) = contents.lineAndCharacter(forByteOffset: byteOffset) else {
                    return nil
            }
            return Location(file: file.path, line: line, character: char)
        }

        return caseLocations
            .filter { $0.character != switchCharacter }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: $0)
            }
    }
}
