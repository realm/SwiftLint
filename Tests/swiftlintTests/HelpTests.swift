//
//  HelpTests.swift
//  swiftlintTests
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest

class HelpTests: XCTestCase {

    var swiftlint: SwiftLintExecutable!

    override func setUp() {
        super.setUp()
        swiftlint = SwiftLintExecutable()
    }

    func testHelpCommand() {
        let result = swiftlint.execute(["help"])
        let expected = "Available commands:\n\n" +
        "   autocorrect   Automatically correct warnings and errors\n" +
        "   help          Display general or command-specific help\n" +
        "   lint          Print lint warnings and errors (default command)\n" +
        "   rules         Display the list of rules and their identifiers\n" +
        "   version       Display the current version of SwiftLint\n"
        assertResultSuccess(result, expected)
    }
}
