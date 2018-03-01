//
//  FunctionBodyLengthRule.swift
//  SwiftLint
//
//  Created by Mikhail Yakushin on 5/24/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FunctionBodyWhitespaceLinesRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 0, error: 0)

    public init() {}

    public static let description = RuleDescription(
            identifier: "function_body_whitespace_lines",
            name: "Function Body Whitespace Lines",
            description: "Function bodies should not have whitespace lines.",
            kind: .style
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds.contains(kind),
              let offset = dictionary.offset,
              let bodyOffset = dictionary.bodyOffset,
              let bodyLength = dictionary.bodyLength,
              let body: String = file.contents.bridge().substringWithByteRange(
                      start: bodyOffset,
                      length: bodyLength
              )
                else {
            return []
        }
        var count = 0
        let lines: [String] = body.components(separatedBy: .newlines)
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                count += 1
            }
        }
        count -= 2 // first and last components are always empty
        return configuration.params.flatMap { (parameter: RuleParameter<Int>) -> [StyleViolation] in
            var violations: [StyleViolation] = [StyleViolation]()
            // swiftlint:disable empty_count
            if count > 0 {
                violations.append(
                        StyleViolation(
                                ruleDescription: type(of: self).description,
                                severity: parameter.severity,
                                location: Location(file: file, byteOffset: offset),
                                reason: "Function body should span \(configuration.warning)" +
                                        " comment and whitespace lines or less " +
                                        ": currently spans \(count) " +
                                        "lines"
                        )
                )
            }
            return violations
        }
    }

}
