//
//  ExtendedNSStringTests.swift
//  SwiftLint
//
//  Created by crimsonwoods on 11/18/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import XCTest

internal class ExtendedNSStringTests: XCTestCase {

    func testLineAndCharacterForByteOffset_forContentsContainingMultibyteCharacters() {
        let contents = "" +
        "import Foundation\n" +                               // 18 characters
        "class Test {\n" +                                    // 13 characters
            "func test() {\n" +                               // 14 characters
                "// 日本語コメント : comment in Japanese\n" +   // 33 characters
                "// do something\n" +                         // 16 characters
            "}\n" +
        "}"
        let string = NSString(string: contents)
        // A character placed on 80 offset indicates a white-space before 'do' at 5th line.
        if let lineAndCharacter = string.lineAndCharacter(forCharacterOffset: 80) {
            XCTAssertEqual(lineAndCharacter.line, 5)
            XCTAssertEqual(lineAndCharacter.character, 3)
        } else {
            XCTFail("NSString.lineAndCharacterForByteOffset should return non-nil tuple.")
        }
    }
}
