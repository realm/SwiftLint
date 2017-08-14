//
//  SourceKitCrashTests.swift
//  SwiftLint
//
//  Created by 野村 憲男 on 2/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class SourceKitCrashTests: XCTestCase {

    func testAssertHandlerIsNotCalledOnNormalFile() {
        let file = File(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.structure
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing File.structure")

        assertHandlerCalled = false
        _ = file.syntaxMap
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing File.syntaxMap")

        assertHandlerCalled = false
        _ = file.syntaxKindsByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing File.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.syntaxTokensByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing File.syntaxTokensByLines")
    }

    func testAssertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = File(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.structure
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing File.structure")

        assertHandlerCalled = false
        _ = file.syntaxMap
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing File.syntaxMap")

        assertHandlerCalled = false
        _ = file.syntaxKindsByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing File.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.syntaxTokensByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was not called on accessing File.syntaxTokensByLines")
    }

    func testRulesWithFileThatCrashedSourceKitService() {
        let file = File(path: #file)!
        file.sourcekitdFailed = true
        file.assertHandler = {
            XCTFail("If this called, rule's SourceKitFreeRule is not properly configured")
        }
        let configuration = Configuration(rulesMode: .whitelisted(allRuleIdentifiers))!
        _ = Linter(file: file, configuration: configuration).styleViolations
        file.sourcekitdFailed = false
        file.assertHandler = nil
    }
}
