//
//  FirebaseDynamicLinksUniversalLinkRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksUniversalLinkRule: ConfigurationProviderRule, OptInRule {

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
            "    let dynamicLink = FIRDynamicLinks.dynamicLinks()?.handleUniversalLink(userActivity.webpageURL!) {" +
            "        (dynamiclink, error) in { \n" +
            "    } \n" +
            "    return true \n" +
            "  }\n" +
            "}"
        ],
        triggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
                "  func application(_ application: UIApplication, continue userActivity: NSUserActivity," +
                "      restorationHandler: @escaping ([Any]?) -> Void) -> Bool {\n" +
                "    return true \n" +
                "  }\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let appDelegate = file.structure.dictionary.substructure
        if let first = appDelegate.first, first.inheritedTypes.contains("UIApplicationDelegate") {
            for method in first.substructure where
                SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind &&
                    method.name == "application(_:continue:restorationHandler:)" {
                for call in method.substructure where call.kind == SwiftExpressionKind.call.rawValue &&
                    call.name!.hasSuffix(".handleUniversalLink") {
                    return []
                }
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severity,
                                       location: Location(file: file, byteOffset: method.offset ?? 0))]
            }
        }
        return []
    }
}
