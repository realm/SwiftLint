//
//  FirebaseCoreRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseCoreRule: RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_core",
        name: "Firebase Core",
        description: "Firebase should be configured before use.",
        nonTriggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication," +
            "      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n" +
            "    FirebaseApp.configure()\n" +
            "    return true \n" +
            "  }\n" +
            "}"
        ],
        triggeringExamples: [
            "class AppDelegate: UIResponder, UIApplicationDelegate {\n" +
            "  func application(_ application: UIApplication," +
            "      didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {\n" +
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
                    method.name == "application(_:didFinishLaunchingWithOptions:)" {
                return validateRecursive(file: file, dictionary: method)
            }
        }
        return []
    }

    public func validateBaseCase(dictionary: [String : SourceKitRepresentable]) -> Bool {
        if let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            dictionary.name == "FirebaseApp.configure" {
            return true
        }
        return false
    }
}
