//
//  QuickDiscouragedCallRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 10/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct QuickDiscouragedFocusedTestRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_focused_test",
        name: "Quick Discouraged Focused Test",
        description: "Discouraged focused test. Other tests won't run while this one is focused.",
        kind: .lint,
        nonTriggeringExamples: [
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       describe(\"foo\") {\n" +
            "           describe(\"bar\") { } \n" +
            "           context(\"bar\") {\n" +
            "               it(\"bar\") { }\n" +
            "           }\n" +
            "           it(\"bar\") { }\n" +
            "       }\n" +
            "   }\n" +
            "}\n"
        ],
        triggeringExamples: [
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       ↓fdescribe(\"foo\") {\n" +
            "       }\n" +
            "   }\n" +
            "}\n",
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       ↓fcontext(\"foo\") {\n" +
            "       }\n" +
            "   }\n" +
            "}\n",
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       ↓fit(\"foo\") {\n" +
            "       }\n" +
            "   }\n" +
            "}\n",
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       describe(\"foo\") {\n" +
            "           ↓fit(\"bar\") { }\n" +
            "       }\n" +
            "   }\n" +
            "}\n",
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       context(\"foo\") {\n" +
            "           ↓fit(\"bar\") { }\n" +
            "       }\n" +
            "   }\n" +
            "}\n",
            "class TotoTests: QuickSpec {\n" +
            "   override func spec() {\n" +
            "       describe(\"foo\") {\n" +
            "           context(\"bar\") {\n" +
            "               ↓fit(\"toto\") { }\n" +
            "        }\n" +
            "   }\n" +
            "}\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let testClasses = file.structure.dictionary.substructure.filter {
            return $0.inheritedTypes.contains("QuickSpec") &&
                $0.kind.flatMap(SwiftDeclarationKind.init) == .class
        }

        let specDeclarations = testClasses.flatMap { classDict in
            return classDict.substructure.filter {
                return $0.name == "spec()" && $0.enclosedVarParameters.isEmpty &&
                    $0.kind.flatMap(SwiftDeclarationKind.init) == .functionMethodInstance &&
                    $0.enclosedSwiftAttributes.contains("source.decl.attribute.override")
            }
        }

        return specDeclarations.flatMap {
            validate(file: file, dictionary: $0)
        }
    }

    private func validate(file: File, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict)
            }

            return violations
        }
    }

    private func validate(file: File,
                          kind: SwiftExpressionKind,
                          dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let name = dictionary.name,
            let offset = dictionary.offset,
            QuickFocusedCallKind(rawValue: name) != nil else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}

private enum QuickFocusedCallKind: String {
    case fdescribe
    case fcontext
    case fit
}
