//
//  VerticalParameterAlignmentRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/22/16.
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
        kind: .style,
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
            "   dictionary: [String: SourceKitRepresentable]) -> [StyleViolation]\n",
            "func validateFunction(\n" +
            "   _ file: File, kind: SwiftDeclarationKind,\n" +
            "   dictionary: [String: SourceKitRepresentable]\n" +
            ") -> [StyleViolation]\n",
            "func regex(_ pattern: String,\n" +
            "           options: NSRegularExpression.Options = [.anchorsMatchLines,\n" +
            "                                                   .dotMatchesLineSeparators]) -> NSRegularExpression\n",
            "func foo(a: Void,\n         b: [String: String] =\n           [:]) {\n}\n",
            "func foo(data: (size: CGSize,\n" +
            "                identifier: String)) {}"
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

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
            let startOffset = dictionary.nameOffset,
            let length = dictionary.nameLength,
            case let endOffset = startOffset + length else {
            return []
        }

        let params = dictionary.substructure.filter { subDict in
            return subDict.kind.flatMap(SwiftDeclarationKind.init) == .varParameter &&
                (subDict.offset ?? .max) < endOffset
        }

        guard params.count > 1 else {
            return []
        }

        let contents = file.contents.bridge()

        let paramLocations = params.flatMap { paramDict -> Location? in
            guard let byteOffset = paramDict.offset,
                let lineAndChar = contents.lineAndCharacter(forByteOffset: byteOffset) else {
                return nil
            }
            return Location(file: file.path, line: lineAndChar.line, character: lineAndChar.character)
        }

        var violationLocations = [Location]()
        let firstParamLoc = paramLocations[0]

        for (index, paramLoc) in paramLocations.enumerated() where index > 0 && paramLoc.line! > firstParamLoc.line! {
            let previousParamLoc = paramLocations[index - 1]
            if previousParamLoc.line! < paramLoc.line! && firstParamLoc.character! != paramLoc.character! {
                violationLocations.append(paramLoc)
            }
        }

        return violationLocations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: $0)
        }
    }
}
