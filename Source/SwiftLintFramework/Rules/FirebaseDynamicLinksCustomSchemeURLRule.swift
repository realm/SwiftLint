//
//  FirebaseDynamicLinksHandleCustomSchemeURLRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksCustomSchemeURLRule: RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_dynamiclinks_customschemeURL",
        name: "Firebase DynamicLinks Handle Custom Scheme URL",
        description: "Firebase DynamicLinks should handle custom scheme URL.",
        nonTriggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication, open url: URL," +
            "      sourceApplication: String?, annotation: Any) -> Bool {\n" +
            "    let dynamicLink = DynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url) \n" +
            "    return true \n" +
            "  }\n" +
            "}"
        ],
        triggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
                "  func application(_ application: UIApplication, open url: URL," +
                "      sourceApplication: String?, annotation: Any) -> Bool {\n" +
                "    return true \n" +
                "  }\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let appDelegate = file.structure.dictionary.substructure
        if let first = appDelegate.first, first.inheritedTypes.contains("UIApplicationDelegate") {
            for method in first.substructure where
                SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind {
                switch method.name! {
                case "application(_:open:options:)", "application(_:open:sourceApplication:annotation:)":
                    return validateRecursive(file: file, dictionary: method)
                default:
                    break
                }
            }
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: first.offset ?? 0))]
        }
        return []
    }

    public func validateBaseCase(dictionary: [String : SourceKitRepresentable]) -> Bool {
        if let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.hasSuffix(".dynamicLink") {
            return true
        }
        return false
    }
}
