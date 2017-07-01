//
//  FirebaseConfigFetchRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseConfigFetchRule: ASTRule, RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_config_fetch",
        name: "Firebase Config Fetch",
        description: "Firebase Config fetch should be called in viewDidLoad().",
        nonTriggeringExamples: [
            "class ViewController: UIViewController {\n" +
            "  override func viewDidLoad() {\n" +
            "    super.viewDidLoad() \n" +
            "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            "        (status, error) -> Void in \n" +
            "    }\n" +
            "  }\n" +
            "}",
            "class ViewController: UIViewController {\n" +
                "  override func viewDidLoad() {\n" +
                "    super.viewDidLoad()\n" +
                "  }\n" +
            "}",
            "class ViewController: UIViewController { }"
        ],
        triggeringExamples: [
            "class ViewController: UIViewController {\n" +
            "  override func viewDidLoad() {\n" +
            "    super.viewDidLoad() \n" +
            "  }\n" +
            "  func fetch {\n " +
            "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            "        (status, error) -> Void in \n" +
            "    }\n" +
            "  }\n" +
            "}",
            "class ViewController: UIViewController {\n" +
            "  func fetch {\n " +
            "    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            "        (status, error) -> Void in \n" +
            "    }\n" +
            "  }\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            SwiftExpressionKind.call == kind,
            let name = dictionary.name, name.hasSuffix(".fetch"),
            let param = dictionary.substructure.first, param.name == "withExpirationDuration",

            let first = file.structure.dictionary.substructure.first,
            first.inheritedTypes.contains("UIViewController")
            else {
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
        guard
            let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.hasSuffix(".fetch"),
            let param = dictionary.substructure.first, param.name == "withExpirationDuration"
            else {
                return false
        }
        return true
    }
}
