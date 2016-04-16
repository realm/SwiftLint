//
//  IntegrationTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/28/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftLintFramework
import XCTest

let config: Configuration = {
    let directory = (((#file as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByDeletingLastPathComponent
    NSFileManager.defaultManager().changeCurrentDirectoryPath(directory)
    return Configuration(path: Configuration.fileName)
}()

class IntegrationTests: XCTestCase {

    func testSwiftLintLints() {
        // This is as close as we're ever going to get to a self-hosting linter.
        let swiftFiles = config.lintableFilesForPath("")
        XCTAssert(swiftFiles.map({$0.path!}).contains(#file), "current file should be included")

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
        let swiftFiles = config.lintableFilesForPath("")
        XCTAssertEqual(swiftFiles.flatMap({
            Linter(file: $0, configuration: config).correct()
        }), [])
    }
}

extension String {
    func withStaticString(@noescape closure: StaticString -> Void) {
        withCString {
            let rawPointer = $0._rawValue
            let byteSize = lengthOfBytesUsingEncoding(NSUTF8StringEncoding)._builtinWordValue
            let isASCII = true._getBuiltinLogicValue()
            // swiftlint:disable:next variable_name
            let staticString = StaticString(_builtinStringLiteral: rawPointer, byteSize: byteSize,
                isASCII: isASCII)
            closure(staticString)
        }
    }
}
