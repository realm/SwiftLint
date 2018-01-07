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

        // Inverted logic
        "XCTAssertEqual(2, foo)",
        "XCTAssertNotEqual(\"false\", foo)",

        // Blank spaces
        "XCTAssertFalse(  foo  )",
        "XCTAssertTrue(  foo  )",
        "XCTAssertNil(  foo  )",
        "XCTAssertNotNil(  foo  )",
        "XCTAssertEqual(  foo  , 2  )",
        "XCTAssertNotEqual(  foo, \"false\")",

        // Optionals
        "XCTAssertFalse(foo?.bar)",
        "XCTAssertTrue(foo!.bar)",
        "XCTAssertNil(foo?.bar)",
        "XCTAssertNotNil(foo!.bar)",
        "XCTAssertEqual(foo?.bar, 2)",
        "XCTAssertNotEqual(foo?.bar, \"false\")"
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

        // Blank spaces
        "↓XCTAssertEqual(foo,true)",
        "↓XCTAssertEqual( foo , false )",
        "↓XCTAssertEqual(  foo  ,  nil  )",

        // Arrays
        "↓XCTAssertEqual(true, [1, 2, 3, true].hasNumbers())",
        "↓XCTAssertEqual([1, 2, 3, true].hasNumbers(), true)",

        // Optionals
        "↓XCTAssertEqual(foo?.bar, false)",
        "↓XCTAssertEqual(foo!.bar, true)",
        "↓XCTAssertEqual(foo?.bar, nil)",
        "↓XCTAssertNotEqual(foo!.bar, nil)"
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

        // Blank spaces
        "↓XCTAssertEqual(foo,true)": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual( true , foo )": "XCTAssertTrue(foo)",
        "↓XCTAssertEqual(  foo  ,  false  )": "XCTAssertFalse(foo)",

        // Commented out code
        "// XCTAssertNotEqual(foo, nil)": "// XCTAssertNotEqual(foo, nil)",
        "/* XCTAssertNotEqual(foo, nil) */": "/* XCTAssertNotEqual(foo, nil) */",

        // Arrays
        "↓XCTAssertEqual(true, [1, 2, 3, true].hasNumbers())": "XCTAssertTrue([1, 2, 3, true].hasNumbers())",
        "↓XCTAssertEqual([1, 2, 3, true].hasNumbers(), true)": "XCTAssertTrue([1, 2, 3, true].hasNumbers())",

        // Optionals
        "↓XCTAssertEqual(foo?.bar, false)": "XCTAssertFalse(foo?.bar)",
        "↓XCTAssertEqual(foo!.bar, true)": "XCTAssertTrue(foo!.bar)",
        "↓XCTAssertEqual(foo?.bar, nil)": "XCTAssertNil(foo?.bar)",
        "↓XCTAssertNotEqual(foo!.bar, nil)": "XCTAssertNotNil(foo!.bar)"
    ]
}
