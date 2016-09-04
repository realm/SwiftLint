//
//  SuperCallRule.swift
//  SwiftLint
//
//  Created by Angel Garcia on 04/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct SuperCallRule: ConfigurationProviderRule, ASTRule, OptInRule {
    public var configuration = SeverityConfiguration(.Warning)

    let methodNames = [
        "viewWillAppear(_:)",
        "viewWillDisappear(_:)",
        "viewDidAppear(_:)",
        "viewDidDisappear(_:)",
        "prepareForSegue(_:sender:)"
    ]


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
        guard kind == .FunctionMethodInstance else { return [] }
        guard   let offset = dictionary["key.bodyoffset"] as? Int64,
                let name = dictionary["key.name"] as? String where methodNames.contains(name),
                let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable]
        else { return [] }

        let superCall = "super.\(name)"
        let callsToSuper: [String] = substructure.flatMap {
            guard   let elems = $0 as? [String: SourceKitRepresentable],
                    let type = elems["key.kind"] as? String,
                    let name = elems["key.name"] as? String
                    where   type == "source.lang.swift.expr.call" &&
                            superCall.containsString(name)
                            else { return nil }
            return name
        }

        if callsToSuper.isEmpty {
            return [StyleViolation(ruleDescription: self.dynamicType.description,
                severity: .Warning,
                location: Location(file: file, byteOffset: Int(offset)),
                reason: "Method '\(name)' should call to super function")]
        } else if callsToSuper.count > 1 {
            return [StyleViolation(ruleDescription: self.dynamicType.description,
                severity: .Warning,
                location: Location(file: file, byteOffset: Int(offset)),
                reason: "Method '\(name)' should call to super only once")]
        }
        return []
    }

}
