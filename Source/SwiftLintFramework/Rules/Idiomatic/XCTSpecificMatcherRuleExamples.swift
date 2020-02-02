internal struct XCTSpecificMatcherRuleExamples {
    static let nonTriggeringExamples = [
        // True/False
        Example("XCTAssertFalse(foo)"),
        Example("XCTAssertTrue(foo)"),

        // Nil/Not nil
        Example("XCTAssertNil(foo)"),
        Example("XCTAssertNotNil(foo)"),

        // Equal/Not equal
        Example("XCTAssertEqual(foo, 2)"),
        Example("XCTAssertNotEqual(foo, \"false\")"),

        // Arrays with key words
        Example("XCTAssertEqual(foo, [1, 2, 3, true])"),
        Example("XCTAssertEqual(foo, [1, 2, 3, false])"),
        Example("XCTAssertEqual(foo, [1, 2, 3, nil])"),
        Example("XCTAssertEqual(foo, [true, nil, true, nil])"),
        Example("XCTAssertEqual([1, 2, 3, true], foo)"),
        Example("XCTAssertEqual([1, 2, 3, false], foo)"),
        Example("XCTAssertEqual([1, 2, 3, nil], foo)"),
        Example("XCTAssertEqual([true, nil, true, nil], foo)"),

        // Inverted logic
        Example("XCTAssertEqual(2, foo)"),
        Example("XCTAssertNotEqual(\"false\"), foo)"),
        Example("XCTAssertEqual(false, foo?.bar)"),
        Example("XCTAssertEqual(true, foo?.bar)"),

        // Blank spaces
        Example("XCTAssertFalse(  foo  )"),
        Example("XCTAssertTrue(  foo  )"),
        Example("XCTAssertNil(  foo  )"),
        Example("XCTAssertNotNil(  foo  )"),
        Example("XCTAssertEqual(  foo  , 2  )"),
        Example("XCTAssertNotEqual(  foo, \"false\")"),

        // Optionals
        Example("XCTAssertEqual(foo?.bar, false)"),
        Example("XCTAssertEqual(foo?.bar, true)"),
        Example("XCTAssertNil(foo?.bar)"),
        Example("XCTAssertNotNil(foo?.bar)"),
        Example("XCTAssertEqual(foo?.bar, 2)"),
        Example("XCTAssertNotEqual(foo?.bar, \"false\")"),

        // Function calls and enums
        Example("XCTAssertEqual(foo?.bar, toto())"),
        Example("XCTAssertEqual(foo?.bar, .toto(.zoo))"),
        Example("XCTAssertEqual(toto(), foo?.bar)"),
        Example("XCTAssertEqual(.toto(.zoo), foo?.bar)")
    ]

    static let triggeringExamples = [
        // Without message
        Example("↓XCTAssertEqual(foo, true)"),
        Example("↓XCTAssertEqual(foo, false)"),
        Example("↓XCTAssertEqual(foo, nil)"),
        Example("↓XCTAssertNotEqual(foo, true)"),
        Example("↓XCTAssertNotEqual(foo, false)"),
        Example("↓XCTAssertNotEqual(foo, nil)"),

        // Inverted logic (just in case...)
        Example("↓XCTAssertEqual(true, foo)"),
        Example("↓XCTAssertEqual(false, foo)"),
        Example("↓XCTAssertEqual(nil, foo)"),
        Example("↓XCTAssertNotEqual(true, foo)"),
        Example("↓XCTAssertNotEqual(false, foo)"),
        Example("↓XCTAssertNotEqual(nil, foo)"),

        // With message
        Example("↓XCTAssertEqual(foo, true, \"toto\")"),
        Example("↓XCTAssertEqual(foo, false, \"toto\")"),
        Example("↓XCTAssertEqual(foo, nil, \"toto\")"),
        Example("↓XCTAssertNotEqual(foo, true, \"toto\")"),
        Example("↓XCTAssertNotEqual(foo, false, \"toto\")"),
        Example("↓XCTAssertNotEqual(foo, nil, \"toto\")"),
        Example("↓XCTAssertEqual(true, foo, \"toto\")"),
        Example("↓XCTAssertEqual(false, foo, \"toto\")"),
        Example("↓XCTAssertEqual(nil, foo, \"toto\")"),
        Example("↓XCTAssertNotEqual(true, foo, \"toto\")"),
        Example("↓XCTAssertNotEqual(false, foo, \"toto\")"),
        Example("↓XCTAssertNotEqual(nil, foo, \"toto\")"),

        // Blank spaces
        Example("↓XCTAssertEqual(foo,true)"),
        Example("↓XCTAssertEqual( foo , false )"),
        Example("↓XCTAssertEqual(  foo  ,  nil  )"),

        // Arrays
        Example("↓XCTAssertEqual(true, [1, 2, 3, true].hasNumbers())"),
        Example("↓XCTAssertEqual([1, 2, 3, true].hasNumbers(), true)"),

        // Optionals
        Example("↓XCTAssertEqual(foo?.bar, nil)"),
        Example("↓XCTAssertNotEqual(foo?.bar, nil)"),

        // Weird cases
        Example("↓XCTAssertEqual(nil, true)"),
        Example("↓XCTAssertEqual(nil, false)"),
        Example("↓XCTAssertEqual(true, nil)"),
        Example("↓XCTAssertEqual(false, nil)"),
        Example("↓XCTAssertEqual(nil, nil)"),
        Example("↓XCTAssertEqual(true, true)"),
        Example("↓XCTAssertEqual(false, false)")
    ]
}
