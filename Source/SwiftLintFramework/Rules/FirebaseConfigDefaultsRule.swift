//
//  FirebaseConfigDefaultsRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseConfigDefaultsRule: ASTRule, RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_config_defaults",
        name: "Firebase Config Defaults",
        description: "Firebase Config defaults should be set.",
        nonTriggeringExamples: [
            "class ViewController: UIViewController {\n" +
            "  override func viewDidLoad() {\n" +
            "    super.viewDidLoad() \n" +
            "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            "        (status, error) -> Void in \n" +
            "    }\n" +
            "    remoteConfig.setDefaults(fromPlist: \"RemoteConfigDefaults\")\n" +
            "  }\n" +
            "}"
        ],
        triggeringExamples: [
            "class ViewController: UIViewController {\n" +
                "  override func viewDidLoad() {\n" +
                "    super.viewDidLoad() \n" +
                "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
                "        (status, error) -> Void in \n" +
                "    }\n" +
                "  }\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftExpressionKind.call == kind else {
            return []
        }

        guard dictionary.name!.hasSuffix(".fetch") else {
            return []
        }

        guard dictionary.substructure[0].name == "withExpirationDuration" else {
            return []
        }

        guard let first = file.structure.dictionary.substructure.first else {
            return []
        }

        guard first.inheritedTypes.contains("UIViewController")  else {
            return []
        }

        for method in first.substructure where
            SwiftDeclarationKind.functionMethodInstance.rawValue == method.kind &&
                method.name == "viewDidLoad()" {
            return validateRecursive(file: file, dictionary: method)
        }
        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: first.offset ?? 0))]
    }

    public func validateBaseCase(dictionary: [String : SourceKitRepresentable]) -> Bool {
        if let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.contains(".setDefaults") {
            return true
        }
        return false
    }
}
