//
//  ProhibitedSuperRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ProhibitedSuperRule: ConfigurationProviderRule, ASTRule, OptInRule {
    public var configuration = ProhibitedSuperConfiguration()

    public init() { }

    public static let description = RuleDescription(
        identifier: "prohibited_super_call",
        name: "Prohibited calls to super",
        description: "Some methods should not call super",
        nonTriggeringExamples: [
            "class VC: UIViewController {\n" +
                "\toverride func loadView() {\n" +
                "\t}\n" +
            "}\n",
            "class NSView {\n" +
                "\tfunc updateLayer() {\n" +
                    "\t\tself.method1()" +
                "\t}\n" +
            "}\n"
        ],
        triggeringExamples: [
            "class VC: UIViewController {\n" +
                "\toverride func loadView() ↓{\n" +
                    "\t\tsuper.loadView()\n" +
                "\t}\n" +
            "}\n",
            "class VC: NSFileProviderExtension {\n" +
                "\toverride func providePlaceholder(at url: URL," +
                "completionHandler: @escaping (Error?) -> Void) ↓{\n" +
                    "\t\tself.method1()\n" +
                    "\t\tsuper.providePlaceholder(at:url, completionHandler: completionHandler)\n" +
                "\t}\n" +
            "}\n",
            "class VC: NSView {\n" +
                "\toverride func updateLayer() ↓{\n" +
                    "\t\tself.method1()\n" +
                    "\t\tsuper.updateLayer()\n" +
                    "\t\tself.method2()\n" +
                "\t}\n" +
            "}\n"
        ]
    )

    public func validateFile(_ file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary["key.bodyoffset"] as? Int64,
            let name = dictionary["key.name"] as? String,
            let substructure = (dictionary["key.substructure"] as? [SourceKitRepresentable]),
            kind == .functionMethodInstance &&
            configuration.resolvedMethodNames.contains(name) &&
            dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.override")
            else { return [] }

        let callsToSuper = extractCallsToSuper(name, substructure: substructure)

        if !callsToSuper.isEmpty {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: Int(offset)),
                                   reason: "Method '\(name)' should not call to super function")]
        }
        return []
    }

    private func extractCallsToSuper(_ name: String,
                                     substructure: [SourceKitRepresentable]) -> [String] {
        let superCall = "super.\(name)"
        return substructure.flatMap {
            guard let elems = $0 as? [String: SourceKitRepresentable],
                let type = elems["key.kind"] as? String,
                let name = elems["key.name"] as? String,
                type == "source.lang.swift.expr.call" && superCall.contains(name)
                else { return nil }
            return name
        }
    }
}
