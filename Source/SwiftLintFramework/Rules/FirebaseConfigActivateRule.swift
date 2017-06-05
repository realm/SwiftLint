//
//  FirebaseConfigActivateRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 3/8/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirebaseConfigActivateRule: ASTRule, ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "firebase_config_activate",
        name: "Firebase Config Activate",
        description: "Firebase Config should be activated.",
        nonTriggeringExamples: [
            "remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
                " (status, error) -> Void in \n self.remoteConfig.activateFetched() \n }"
        ],
        triggeringExamples: [
            "remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) {" +
                " (status, error) -> Void in \n }"
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

        let fetchClosure = dictionary.substructure[1].substructure[2]
        if isFetchActivated (dictionary: fetchClosure) {
           return []
        } else {
           return [StyleViolation(ruleDescription: type(of: self).description,
                            severity: configuration.severity,
                            location: Location(file: file, byteOffset: fetchClosure.offset ?? 0))]
        }
    }

    private func isFetchActivated (dictionary: [String: SourceKitRepresentable]) -> Bool {
        if let kindString = dictionary.kind, SwiftExpressionKind(rawValue: kindString) == .call,
            let name = dictionary.name, name.hasSuffix(".activateFetched") {
            return true
        }

        for subDict in dictionary.substructure {
            if isFetchActivated(dictionary: subDict) {
                return true
            }
        }

        return false
    }
}
