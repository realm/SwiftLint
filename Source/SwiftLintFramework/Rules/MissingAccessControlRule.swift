//
//  MissingAccessControlRule.swift
//  SwiftLint
//
//  Created by Kai Aldag on 2016-08-09.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct MissingAccessControlRule: Rule {

    public var configuration = SeverityConfiguration(.Warning)
    public let parameters: [RuleParameter<AccessControlLevel>]

    public init(configuration: AnyObject) throws {
        guard let array = [String].arrayOf(configuration) else {
            throw ConfigurationError.UnknownConfiguration
        }
        let acl = array.flatMap { AccessControlLevel(rawValue: $0) }
        parameters = zip([.Warning, .Error], acl).map(RuleParameter<AccessControlLevel>.init)
    }

    public init() {
        parameters = [RuleParameter(severity: .Warning, value: .Public)]
    }

    private func matchPattern(decleration: String) -> NSString? {
        guard let matches = regex("^\\s*(?!private|fileprivate|internal|public)" +
                                  "\\s*(?:class|(final\\s+class)|struct|enum)\\s+")
        .matchesInString(decleration, options: [],
                         range: NSRange(location: 0,
                            length: decleration.characters.count)).first else {
                            return nil
        }

        return NSString(string: decleration).substringWithRange(matches.range)
    }

    public static let description = RuleDescription(
        identifier: "missing_access_control",
        name: "Missing Access_Control",
        description: "All types should have specified Access-Control.",
        nonTriggeringExamples: [
            "internal enum A {}\n",
            "public final class B {}\n",
            "private struct C {}\n"
        ],
        triggeringExamples: [
            "enum A {}\n",
            "final class B {}\n",
            "struct C {}\n"
        ]
    )

    public var configurationDescription: String {
        return parameters.map({
            "\($0.severity.rawValue.lowercaseString): \($0.value.rawValue)"
        }).joinWithSeparator(", ")
    }

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.flatMap {
            guard matchPattern($0.content) != nil else { return nil }
            return StyleViolation(ruleDescription: MissingAccessControlRule.description,
                                  severity: configuration.severity,
                                  location: Location(file: file.path,
                                                     line: $0.index,
                                                     character: nil),
                                  reason: nil)
        }
    }

    public func isEqualTo(rule: Rule) -> Bool {
        guard let accessControlRule = rule as? MissingAccessControlRule else { return false }
        return accessControlRule.parameters == parameters
    }
}
