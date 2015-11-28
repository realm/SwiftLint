//
//  TestHelpers.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SwiftLintFramework
import SourceKittenFramework
import XCTest

let allRuleIdentifiers = Configuration.rulesFromYAML().map {
    $0.dynamicType.description.identifier
}

func violations(string: String, config: Configuration = Configuration()) -> [StyleViolation] {
    return Linter(file: File(contents: string), configuration: config).styleViolations
}

private func violations(string: String, _ description: RuleDescription) -> [StyleViolation] {
    let disabledRules = allRuleIdentifiers.filter { $0 != description.identifier }
    return violations(string, config: Configuration(disabledRules: disabledRules)!)
}

private func assertCorrection(before: String, expected: String) {
    guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .URLByAppendingPathComponent(NSUUID().UUIDString + ".swift").path else {
        XCTFail("coun't generate temporary path for assertCorrection()")
        return
    }
    if before.dataUsingEncoding(NSUTF8StringEncoding)?.writeToFile(path, atomically: true) != true {
        XCTFail("coun't write to file for assertCorrection()")
        return
    }
    guard let file = File(path: path) else {
        XCTFail("couldn't read file at path '\(path)' for assertCorrection()")
        return
    }
    Linter(file: file).correct()
    XCTAssertEqual(file.contents, expected)
    do {
        let corrected = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        XCTAssertEqual(corrected, expected)
    } catch {
        XCTFail("coun't read file at path '\(path)': \(error)")
    }
}

extension String {
    private func toStringLiteral() -> String {
        return "\"" + stringByReplacingOccurrencesOfString("\n", withString: "\\n") + "\""
    }
}

extension XCTestCase {
    func verifyRule(ruleDescription: RuleDescription, commentDoesntViolate: Bool = true,
                    stringDoesntViolate: Bool = true) {
        let triggers = ruleDescription.triggeringExamples
        let nonTriggers = ruleDescription.nonTriggeringExamples

        // Non-triggering examples don't violate
        XCTAssert(nonTriggers.flatMap({ violations($0, ruleDescription) }).isEmpty)

        // Triggering examples violate
        XCTAssertEqual(triggers.flatMap({ violations($0, ruleDescription) }).count, triggers.count)

        // Comment doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations("/*\n  " + $0 + "\n */", ruleDescription) }).count,
            commentDoesntViolate ? 0 : triggers.count
        )

        // String doesn't violate
        XCTAssertEqual(
            triggers.flatMap({ violations($0.toStringLiteral(), ruleDescription) }).count,
            stringDoesntViolate ? 0 : triggers.count
        )

        // "disable" command doesn't violate
        let command = "// swiftlint:disable \(ruleDescription.identifier)\n"
        XCTAssert(triggers.flatMap({ violations(command + $0, ruleDescription) }).isEmpty)

        // corrections
        ruleDescription.corrections.forEach(assertCorrection)
    }
}
