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
        "XCTAssertEqual(false, foo?.bar)",
        "XCTAssertEqual(true, foo?.bar)",

        // Blank spaces
        "XCTAssertFalse(  foo  )",
        "XCTAssertTrue(  foo  )",
        "XCTAssertNil(  foo  )",
        "XCTAssertNotNil(  foo  )",
        "XCTAssertEqual(  foo  , 2  )",
        "XCTAssertNotEqual(  foo, \"false\")",

        // Optionals
        "XCTAssertEqual(foo?.bar, false)",
        "XCTAssertEqual(foo?.bar, true)",
        "XCTAssertNil(foo?.bar)",
        "XCTAssertNotNil(foo?.bar)",
        "XCTAssertEqual(foo?.bar, 2)",
        "XCTAssertNotEqual(foo?.bar, \"false\")",

        // Function calls and enums
        "XCTAssertEqual(foo?.bar, toto())",
        "XCTAssertEqual(foo?.bar, .toto(.zoo))",
        "XCTAssertEqual(toto(), foo?.bar)",
        "XCTAssertEqual(.toto(.zoo), foo?.bar)"
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
        "↓XCTAssertEqual(  foo  ,  nil  )",

        // Arrays
        "↓XCTAssertEqual(true, [1, 2, 3, true].hasNumbers())",
        "↓XCTAssertEqual([1, 2, 3, true].hasNumbers(), true)",

        // Optionals
        "↓XCTAssertEqual(foo?.bar, nil)",
        "↓XCTAssertNotEqual(foo?.bar, nil)",

        // Weird cases
        "↓XCTAssertEqual(nil, true)",
        "↓XCTAssertEqual(nil, false)",
        "↓XCTAssertEqual(true, nil)",
        "↓XCTAssertEqual(false, nil)",
        "↓XCTAssertEqual(nil, nil)",
        "↓XCTAssertEqual(true, true)",
        "↓XCTAssertEqual(false, false)"
    ]
}
