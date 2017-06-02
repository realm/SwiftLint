//
//  IntegrationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftLintFramework
import XCTest

let config: Configuration = {
    let directory = #file.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent
    _ = FileManager.default.changeCurrentDirectoryPath(directory)
    return Configuration(path: Configuration.fileName)
}()

class IntegrationTests: XCTestCase {

    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let swiftFiles = config.lintableFiles(inPath: "")
        XCTAssert(swiftFiles.map({ $0.path! }).contains(#file), "current file should be included")

        let violations = swiftFiles.flatMap {
            Linter(file: $0, configuration: config).styleViolations
        }
        violations.forEach { violation in
            violation.location.file!.withStaticString {
                XCTFail(violation.reason, file: $0, line: UInt(violation.location.line!))
            }
        }
    }

    func testSwiftLintAutoCorrects() {
        let swiftFiles = config.lintableFiles(inPath: "")
        let corrections = swiftFiles.flatMap { Linter(file: $0, configuration: config).correct() }
        for correction in corrections {
            correction.location.file!.withStaticString {
                XCTFail(correction.ruleDescription.description,
                        file: $0, line: UInt(correction.location.line!))
            }
        }
    }
}

extension String {
    func withStaticString(_ closure: (StaticString) -> Void) {
        withCString {
            let rawPointer = $0._rawValue
            let byteSize = lengthOfBytes(using: .utf8)._builtinWordValue
            let isASCII = true._getBuiltinLogicValue()
            let staticString = StaticString(_builtinStringLiteral: rawPointer,
                                            utf8CodeUnitCount: byteSize,
                                            isASCII: isASCII)
            closure(staticString)
        }
    }
}
