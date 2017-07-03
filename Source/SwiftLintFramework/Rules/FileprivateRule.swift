//
//  FilePrivateRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FilePrivateRule: Rule, ConfigurationProviderRule {
    public var configuration = FilePrivateConfiguration(strict: false)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fileprivate",
        name: "FilePrivate",
        description: "Prefer private over fileprivate declarations.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "private extension String {}",
            "public \n enum MyEnum {}",
            "open extension \n String {}",
            "internal extension String {}",
            "extension String {\nfileprivate func Something(){}\n}",
            "class MyClass {\nfileprivate let myInt = 4\n}",
            "class MyClass {\nfileprivate(set) var myInt = 4\n}",
            "struct Outter {\nstruct Inter {\nfileprivate struct Inner {}\n}\n}"
        ],
        triggeringExamples: [
            "fileprivate ↓enum MyEnum {}",
            "fileprivate ↓extension String {}",
            "fileprivate \n ↓extension String {}",
            "fileprivate ↓extension \n String {}",
            "fileprivate ↓class MyClass {\nfileprivate(set) var myInt = 4\n}",
            "fileprivate ↓extension String {}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        if configuration.strict {
            return strictValidate(file: file)
        } else {
            return validateTopLevelDeclarations(file: file)
        }
    }

    private func validateTopLevelDeclarations(file: File) -> [StyleViolation] {
        let offsets = file.structure.dictionary.substructure.flatMap { dictionary -> Int? in
            guard let offset = dictionary.offset,
                dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)) == .fileprivate else {
                    return nil
            }

            return offset
        } + validateTopLevelExtensions(file: file)

        return offsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func validateTopLevelExtensions(file: File) -> [Int] {
        let syntaxTokens = file.syntaxMap.tokens
        let contents = file.contents.bridge()

        return file.structure.dictionary.substructure.flatMap { dictionary -> Int? in
            guard dictionary.kind.flatMap(SwiftDeclarationKind.init) == .extension,
                let offset = dictionary.offset else {
                return nil
            }

            let parts = syntaxTokens.prefix { offset > $0.offset }
            guard let lastKind = parts.last,
                SyntaxKind(rawValue: lastKind.type) == .attributeBuiltin,
                let aclName = contents.substringWithByteRange(start:lastKind.offset, length: lastKind.length),
                AccessControlLevel(description: aclName) == .fileprivate else {
                    return nil
            }

            return offset
        }
    }

    private func strictValidate(file: File) -> [StyleViolation] {
        // Mark all fileprivate occurences as a violation
        return file.match(pattern: "fileprivate", with: [.attributeBuiltin]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           location: Location(file: file, characterOffset: $0.location),
                           reason: "fileprivate should be avoided.")
        }
    }
}
