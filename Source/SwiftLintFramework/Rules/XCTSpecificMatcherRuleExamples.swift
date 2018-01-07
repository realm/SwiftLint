//
//  XCTSpecificMatcherRuleExamples.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/7/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation

internal struct XCTSpecificMatcherRuleExamples {

    static let nonTriggeringExamples = [
        // True/False
        "XCTAssertFalse(foo)",
        "XCTAssertTrue(foo)",

        // Nil/Not nil
        "XCTAssertNil(foo)",
        "XCTAssertNotNil(foo)",

        // Equal/Not equal
        "XCTAssertEqual(foo, 2)",
        "XCTAssertNotEqual(foo, \"false\")",

        // There's no need to touch commented out code
        "// XCTAssertEqual(foo, true)",
        "/* XCTAssertEqual(foo, true) */",

        // Arrays with key words
        "XCTAssertEqual(foo, [1, 2, 3, true])",
        "XCTAssertEqual(foo, [1, 2, 3, false])",
        "XCTAssertEqual(foo, [1, 2, 3, nil])",
        "XCTAssertEqual(foo, [true, nil, true, nil])",
        "XCTAssertEqual([1, 2, 3, true], foo)",
        "XCTAssertEqual([1, 2, 3, false], foo)",
        "XCTAssertEqual([1, 2, 3, nil], foo)",
        "XCTAssertEqual([true, nil, true, nil], foo)",

        // Blank spaces
        "XCTAssertFalse(  foo  )",
        "XCTAssertTrue(  foo  )",
        "XCTAssertNil(  foo  )",
        "XCTAssertNotNil(  foo  )",
        "XCTAssertEqual(  foo  , 2  )",
        "XCTAssertNotEqual(  foo, \"false\")"
    ]

    static let triggeringExamples = [
        // Without message
        "↓XCTAssertEqual(foo, true)",
        "↓XCTAssertEqual(foo, false)",
        "↓XCTAssertEqual(foo, nil)",
        "↓XCTAssertNotEqual(foo, true)",
        "↓XCTAssertNotEqual(foo, false)",
        "↓XCTAssertNotEqual(foo, nil)",

        // Inverted logic (just in case...)
        "↓XCTAssertEqual(true, foo)",
        "↓XCTAssertEqual(false, foo)",
        "↓XCTAssertEqual(nil, foo)",
        "↓XCTAssertNotEqual(true, foo)",
        "↓XCTAssertNotEqual(false, foo)",
        "↓XCTAssertNotEqual(nil, foo)",

        // With message
        "↓XCTAssertEqual(foo, true, \"toto\")",
        "↓XCTAssertEqual(foo, false, \"toto\")",
        "↓XCTAssertEqual(foo, nil, \"toto\")",
        "↓XCTAssertNotEqual(foo, true, \"toto\")",
        "↓XCTAssertNotEqual(foo, false, \"toto\")",
        "↓XCTAssertNotEqual(foo, nil, \"toto\")",
        "↓XCTAssertEqual(true, foo, \"toto\")",
        "↓XCTAssertEqual(false, foo, \"toto\")",
        "↓XCTAssertEqual(nil, foo, \"toto\")",
        "↓XCTAssertNotEqual(true, foo, \"toto\")",
        "↓XCTAssertNotEqual(false, foo, \"toto\")",
        "↓XCTAssertNotEqual(nil, foo, \"toto\")",

        // Blank spaces
        "↓XCTAssertEqual(foo,true)",
        "↓XCTAssertEqual( foo , false )",
        "↓XCTAssertEqual(  foo  ,  nil  )"
    ]

    static let corrections = [
        // Without message
        "↓XCTAssertEqual(foo, true)": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual(true, foo)": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual(foo, false)": "XCTAssertFalse(foo)",
        "↓XCTAssertNotEqual(foo, true)": "XCTAssertFalse(foo)",
        "↓XCTAssertNotEqual(foo, false)": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual(foo, nil)": "XCTAssertNil(foo)",
        "↓XCTAssertNotEqual(foo, nil)": "XCTAssertNotNil(foo)",

        // With message
        "↓XCTAssertEqual(foo, true, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
        "↓XCTAssertEqual(true, foo, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
        "↓XCTAssertEqual(foo, false, \"toto\")": "XCTAssertFalse(foo, \"toto\")",
        "↓XCTAssertNotEqual(foo, true, \"toto\")": "XCTAssertFalse(foo, \"toto\")",
        "↓XCTAssertNotEqual(foo, false, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
        "↓XCTAssertEqual(foo, nil, \"toto\")": "XCTAssertNil(foo, \"toto\")",
        "↓XCTAssertNotEqual(foo, nil, \"toto\")": "XCTAssertNotNil(foo, \"toto\")",

        // Blank spaces
        "↓XCTAssertEqual(foo,true)": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual( true , foo )": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual(  foo  ,  false  )": "XCTAssertFalse(foo)",
        "↓XCTAssertEqual(  foo  ,  false  , \"toto\")": "XCTAssertFalse(foo, \"toto\")",

        // Commented out code
        "// XCTAssertNotEqual(foo, nil)": "// XCTAssertNotEqual(foo, nil)",
        "/* XCTAssertNotEqual(foo, nil) */": "/* XCTAssertNotEqual(foo, nil) */"
    ]
}
