//
//  FileprivateConfiguration.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct FileprivateConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var strict: Bool

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", strict: \(strict)"
    }

    public init(strict: Bool) {
        self.strict = strict
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let strict = configuration["strict"] as? Bool {
            self.strict = strict
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static let fileprivateLimited = RuleDescription(
        identifier: "fileprivate",
        name: "Limit Fileprivate",
        description: "Prefer private over fileprivate for top-level declarations",
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
            "fileprivate enum MyEnum {}",
            "fileprivate extension String {}",
            "fileprivate \n extension String {}",
            "fileprivate extension \n String {}",
            "fileprivate class MyClass {\nfileprivate(set) var myInt = 4\n}",
            "fileprivate extension String {}"
            ]
    )

    public static let fileprivateDisallowed = RuleDescription(
        identifier: "fileprivate",
        name: "Fileprivate Disallowed",
        description: "Fileprivate should be rare. Consider refactoring",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "private extension String {}",
            "public \n extension String {}",
            "open extension \n String {}",
            "internal extension String {}",
            ""
            ],
        triggeringExamples: [
            "fileprivate extension String {}",
            "fileprivate extension String {}",
            "fileprivate \n extension String {}",
            "fileprivate extension \n String {}",
            "fileprivate extension String {}",
            "extension String {\nfileprivate func Something(){}\n}",
            "class MyClass {\nfileprivate let myInt = 4\n}",
            "class MyClass {\nfileprivate(set) var myInt = 4\n}",
            "struct Outter {\nstruct Inter {\nfileprivate struct Inner {}\n}\n}"
            ]
    )

    public static func == (lhs: FileprivateConfiguration,
                           rhs: FileprivateConfiguration) -> Bool {
        return lhs.strict == rhs.strict &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
