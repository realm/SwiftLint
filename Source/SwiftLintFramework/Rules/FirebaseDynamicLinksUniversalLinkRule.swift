//
//  FirebaseDynamicLinksUniversalLinkRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksUniversalLinkRule: RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_dynamiclinks_universallink",
        name: "Firebase DynamicLinks Handle UniversalLink",
        description: "Firebase DynamicLinks should handle universal links.",
        nonTriggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication, continue userActivity: NSUserActivity," +
            "      restorationHandler: @escaping ([Any]?) -> Void) -> Bool {\n" +
            "    let handled = DynamicLinks.dynamicLinks()?.handleUniversalLink(userActivity.webpageURL!) {" +
            "        (dynamiclink, error) in { \n" +
            "    } \n" +
            "    return true \n" +
            "  }\n" +
            "}",
            "class foo { }"
        ],
        triggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
                "  func application(_ application: UIApplication, continue userActivity: NSUserActivity," +
                "      restorationHandler: @escaping ([Any]?) -> Void) -> Bool {\n" +
                "    return true \n" +
                "  }\n" +
            "}",
            "class AppDelegate: UIResponder, UIApplicationDelegate { }"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let appDelegate = file.structure.dictionary.substructure
        guard let first = appDelegate.first, first.inheritedTypes.contains("UIApplicationDelegate") else {
            return []
        }

        for method in first.substructure where
            SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind &&
                method.name == "application(_:continue:restorationHandler:)" {
            return validateRecursive(file: file, dictionary: method)
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: first.offset ?? 0))]
    }

    public func validateBaseCase(dictionary: [String : SourceKitRepresentable]) -> Bool {
        guard
            let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.hasSuffix(".handleUniversalLink")
            else {
                return false
        }
        return true
    }
}
