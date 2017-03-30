//
//  FirebaseConfigFetchRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseConfigFetchRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_config_fetch",
        name: "Firebase Config Fetch",
        description: "Firebase Config fetch should be called.",
        nonTriggeringExamples: [
            "class ViewController: UIViewController {\n" +
            "  override func viewDidLoad() {\n" +
            "    super.viewDidLoad() \n" +
            "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            "        (status, error) -> Void in \n" +
            "    }\n" +
            "  }\n" +
            "}"
        ],
        triggeringExamples: [
            "class ViewController: UIViewController {\n" +
            "  override func viewDidLoad() {\n" +
            "    super.viewDidLoad() \n" +
            "  }\n" +
            "}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let controller = file.structure.dictionary.substructure
        if let first = controller.first, first.inheritedTypes.contains("UIViewController") {
            for method in first.substructure where
                SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind &&
                    method.name == "viewDidLoad()" {
                for call in method.substructure where call.kind == SwiftExpressionKind.call.rawValue
                    && call.name!.contains(".fetch") {
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
