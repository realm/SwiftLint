//
//  FirebaseDynamicLinksSchemeURLRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksSchemeURLRule: RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_dynamiclinks_schemeURL",
        name: "Firebase DynamicLinks SchemeURL",
        description: "Firebase DynamicLinks schemeURL should be set.",
        nonTriggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication," +
            "      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n" +
            "    FirebaseOptions.defaultOptions()?.deepLinkURLScheme = self.customURLScheme\n" +
            "    return true \n" +
            "  }\n" +
            "}",
            "class foo { }"
        ],
        triggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication," +
            "      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n" +
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
                method.name == "application(_:didFinishLaunchingWithOptions:)" {
            return validateRecursive(file: file, dictionary: method)
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: first.offset ?? 0))]
    }

    public func validateBaseCase(dictionary: [String : SourceKitRepresentable]) -> Bool {
        guard
            let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            dictionary.name == "FirebaseOptions.defaultOptions"
            else {
                return false
        }
        return true
    }
}
