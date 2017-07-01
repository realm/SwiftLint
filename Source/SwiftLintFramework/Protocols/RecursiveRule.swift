//
//  RecursiveRule.swift
//  SwiftLint
//
//  Created by Ibrahim Ulukaya (Google Inc.) on 6/5/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol RecursiveRule: ConfigurationProviderRule {
    func validateBaseCase(dictionary: [String: SourceKitRepresentable]) -> Bool
}

extension RecursiveRule {
    public func validateRecursive(file: File, dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return validateRecursive(dictionary: dictionary) ? [] :
            [StyleViolation(ruleDescription: type(of: self).description,
                            severity: ViolationSeverity(rawValue: configuration.consoleDescription)!,
                            location: Location(file: file, byteOffset: dictionary.offset ?? 0))]
    }
    public func validateRecursive(dictionary: [String: SourceKitRepresentable]) -> Bool {
        if validateBaseCase(dictionary: dictionary) {
            return true
        }

        for subDict in dictionary.substructure {
            if validateRecursive(dictionary: subDict) {
                return true
            }
        }

        return false
    }
}
