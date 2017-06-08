//
//  FirebaseConfigActivateRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseConfigActivateRule: ASTRule, RecursiveRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_config_activate",
        name: "Firebase Config Activate",
        description: "Firebase Config should be activated.",
        nonTriggeringExamples: [
            "remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
                " (status, error) -> Void in \n self.remoteConfig.activateFetched() \n }",
            "foo.fetch() { }",
            "foo.fetch(fromURL: URL) { }"
        ],
        triggeringExamples: [
            "remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
                " (status, error) -> Void in \n }",
            "remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
            " (status, error) -> Void in \n foo.fetch() \n }"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            SwiftExpressionKind.call == kind,
            let name = dictionary.name, name.hasSuffix(".fetch"),
            let param = dictionary.substructure.first, param.name == "withExpirationDuration"
            else {
                return []
        }

        let fetchClosure = dictionary.substructure[1].substructure[2]
        return validateRecursive(file: file, dictionary: fetchClosure)
    }

    public func validateBaseCase(dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard
            let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.hasSuffix(".activateFetched")
            else {
                return false
        }
        return true
    }
}
