//
//  VerticalParameterAlignmentRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 22/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VerticalParameterAlignmentRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "vertical_parameter_alignment",
        name: "Vertical Parameter Alignment",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a declaration.",
        nonTriggeringExamples: [
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]\n",
            "func foo(bar: Int)\n",
            "func foo(bar: Int) -> String \n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                      dictionary: [String: SourceKitRepresentable])\n" +
            "                      -> [StyleViolation]\n",
            "func validateFunction(\n" +
            "   _ file: File, kind: SwiftDeclarationKind,\n" +
            "   dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]\n"
        ],
        triggeringExamples: [
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                  ↓dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File, kind: SwiftDeclarationKind,\n" +
            "                       ↓dictionary: [String: SourceKitRepresentable]) { }\n",
            "func validateFunction(_ file: File,\n" +
            "                  ↓kind: SwiftDeclarationKind,\n" +
            "                  ↓dictionary: [String: SourceKitRepresentable]) { }\n"
        ]
    )

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds().contains(kind) else {
            return []
        }

        let contents = file.contents.bridge()
        let pattern = "\\(\\s*(\\S)"

        guard let nameOffset = (dictionary["key.nameoffset"] as? Int64).flatMap({ Int($0) }),
            let nameLength = (dictionary["key.namelength"] as? Int64).flatMap({ Int($0) }),
            let nameRange = contents.byteRangeToNSRange(start: nameOffset, length: nameLength),
            let paramStart = regex(pattern).firstMatch(in: file.contents,
                                                       options: [], range: nameRange)?.rangeAt(1).location,
            let (startLine, startCharacter) = contents.lineAndCharacter(forCharacterOffset: paramStart),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: nameOffset + nameLength - 1),
            endLine > startLine else {
                return []
        }

        let linesRange = (startLine + 1)...endLine
        let violationLocations = linesRange.flatMap { lineIndex -> Int? in
            let line = file.lines[lineIndex - 1]
            guard let paramLocation = regex("\\S").firstMatch(in: file.contents, options: [],
                                                              range: line.range)?.range.location,
                let (_, paramCharacter) = contents.lineAndCharacter(forCharacterOffset: paramLocation),
                paramCharacter != startCharacter else {
                    return nil
            }

            return paramLocation
        }

        return violationLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0))
        }
    }
}
