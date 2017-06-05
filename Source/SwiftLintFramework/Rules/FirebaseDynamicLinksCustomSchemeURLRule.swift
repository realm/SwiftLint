//
//  FirebaseDynamicLinksHandleCustomSchemeURLRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksCustomSchemeURLRule: ConfigurationProviderRule, OptInRule {

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
            var offset: Int?
            for method in first.substructure where
                SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind {
                switch method.name! {
                case "application(_:open:options:)":
                    for call in method.substructure where call.kind == SwiftExpressionKind.call.rawValue &&
                        call.name!.hasSuffix(".dynamicLink") {
                        return []
                    }
                    offset = method.offset
                case "application(_:open:sourceApplication:annotation:)":
                    for call in method.substructure where call.kind == SwiftExpressionKind.call.rawValue &&
                        call.name!.hasSuffix(".dynamicLink") {
                        return []
                    }
                    offset = method.offset
                default:
                    break
                }
            }
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset ?? 0))]
        }
        return []
    }
}
