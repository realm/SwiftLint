//
//  SuperCallRule.swift
//  SwiftLint
//
//  Created by Angel Garcia on 04/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct SuperCallRule: ConfigurationProviderRule, ASTRule, OptInRule {
    public var configuration = SuperCallConfiguration()

    public init() { }

    public static let description = RuleDescription(
        identifier: "overriden_method_call_super",
        name: "Overriden methods call super",
        description: "Some Overriden methods should always call super",
        nonTriggeringExamples: [
            "class VC: UIViewController {\n" +
                "\toverride func viewWillAppear(animated: Bool) {\n" +
                    "\t\tsuper.viewWillAppear(animated)\n" +
                "\t}\n" +
            "}\n",
            "class VC: UIViewController {\n" +
                "\toverride func viewWillAppear(animated: Bool) {\n" +
                    "\t\tself.method1()\n" +
                    "\t\tsuper.viewWillAppear(animated)\n" +
                    "\t\tself.method2()\n" +
                "\t}\n" +
            "}\n",
            "class VC: UIViewController {\n" +
                "\toverride func loadView() {\n" +
                "\t}\n" +
            "}\n",
            "class Some {\n" +
                "\tfunc viewWillAppear(animated: Bool) {\n" +
                "\t}\n" +
            "}\n"
        ],
        triggeringExamples: [
            "class VC: UIViewController {\n" +
                "\toverride func viewWillAppear(animated: Bool) () ↓{\n" +
                    "\t\tself.method()\n" +
                "\t}\n" +
            "}\n",
        ]
    )


    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard   let offset = dictionary["key.bodyoffset"] as? Int64,
                let name = dictionary["key.name"] as? String,
                let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable]
        else { return [] }

        guard   kind == .FunctionMethodInstance &&
                configuration.resolvedMethodNames.contains(name) &&
                extractAttributes(dictionary).contains("source.decl.attribute.override")
        else { return [] }

        let callsToSuper = extractCallsToSuper(name, substructure: substructure)

        if callsToSuper.isEmpty {
            return [StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: Int(offset)),
                reason: "Method '\(name)' should call to super function")]
        } else if callsToSuper.count > 1 {
            return [StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: Int(offset)),
                reason: "Method '\(name)' should call to super only once")]
        }
        return []
    }

    private func extractAttributes(dictionary: [String: SourceKitRepresentable]) -> [String] {
        guard let attributesDict = dictionary["key.attributes"] as? [SourceKitRepresentable]
            else { return [] }
        return attributesDict.flatMap {
            ($0 as? [String: SourceKitRepresentable])?["key.attribute"] as? String
        }
    }

    private func extractCallsToSuper(name: String,
                                     substructure: [SourceKitRepresentable]) -> [String] {
        let superCall = "super.\(name)"
        return substructure.flatMap {
            guard let elems = $0 as? [String: SourceKitRepresentable],
                type = elems["key.kind"] as? String,
                name = elems["key.name"] as? String
                where   type == "source.lang.swift.expr.call" &&
                    superCall.containsString(name)
                else { return nil }
            return name
        }
    }
}
