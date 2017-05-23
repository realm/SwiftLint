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

    public init() {}

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
                "\toverride func loadView() {↓\n" +
                    "\t\tsuper.loadView()\n" +
                "\t}\n" +
            "}\n",
            "class VC: NSFileProviderExtension {\n" +
                "\toverride func providePlaceholder(at url: URL," +
                "completionHandler: @escaping (Error?) -> Void) {↓\n" +
                    "\t\tself.method1()\n" +
                    "\t\tsuper.providePlaceholder(at:url, completionHandler: completionHandler)\n" +
                "\t}\n" +
            "}\n",
            "class VC: NSView {\n" +
                "\toverride func updateLayer() {↓\n" +
                    "\t\tself.method1()\n" +
                    "\t\tsuper.updateLayer()\n" +
                    "\t\tself.method2()\n" +
                "\t}\n" +
            "}\n",
            "class VC: NSView {\n" +
                "\toverride func updateLayer() {↓\n" +
                "\t\tdefer {\n" +
                "\t\t\tsuper.updateLayer()\n" +
                "\t\t}\n" +
                "\t}\n" +
            "}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.bodyOffset,
            let name = dictionary.name,
            kind == .functionMethodInstance,
            configuration.resolvedMethodNames.contains(name),
            dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.override"),
            !dictionary.extractCallsToSuper(methodName: name).isEmpty
            else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset),
                               reason: "Method '\(name)' should not call to super function")]
    }
}
