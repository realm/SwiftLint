//
//  FirebaseDynamicLinksSchemeURLRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseDynamicLinksSchemeURLRule: ConfigurationProviderRule, OptInRule {

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
            "    FIROptions.default().deepLinkURLScheme = self.customURLScheme\n" +
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
                switch SwiftVersion.current {
                case .two:
                    let methodRange = file.contents.bridge().byteRangeToNSRange(start: method.bodyOffset!,
                                                                                length: method.bodyLength!)
                    if !file.match(pattern: "deepLinkURLScheme =",
                                   excludingSyntaxKinds: SyntaxKind.commentAndStringKinds(),
                                   range: methodRange).isEmpty {
                        return []
                    }
                case .three:
                    for call in method.substructure where call.kind == SwiftExpressionKind.call.rawValue &&
                        call.name! == "FIROptions.default" {
                            return []
                    }
                default: break
                }
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severity,
                                       location: Location(file: file, byteOffset: method.offset ?? 0))]
            }
        }
        return []
    }
}
