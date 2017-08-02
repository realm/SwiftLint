//
//  XCTFailMessageRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/2/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct XCTFailMessageRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xctfail_message",
        name: "XCTFail Message",
        description: "An XCTFail call should include a description of the assertion.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "func testFoo() {\n" +
            "    XCTFail(\"bar\")\n" +
            "}",
            "func testFoo() {\n" +
            "    XCTFail(bar)\n" +
            "}"
        ],
        triggeringExamples: [
            "func testFoo() {\n" +
            "    ↓XCTFail()\n" +
            "}",
            "func testFoo() {\n" +
            "    ↓XCTFail(\"\")\n" +
            "}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "XCTFail",
            hasEmptyMessage(dictionary: dictionary, file: file)
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }

    private func hasEmptyMessage(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength else { return false }

        guard bodyLength > 0 else { return true }

        let body = file.contents.bridge().substringWithByteRange(start: bodyOffset, length: bodyLength)
        return body == "\"\""
    }
}
