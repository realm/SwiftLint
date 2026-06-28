internal struct XCTSpecificMatcherRuleExamples {
    static let nonTriggeringExamples = [
        // True/False
        Example("XCTAssert(foo"),
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
        Example("XCTAssert(    foo  )"),
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
        Example("XCTAssertEqual(.toto(.zoo), foo?.bar)"),

        // Configurations Disabled
        Example("XCTAssertEqual(foo, true)",
                configuration: ["matchers": ["one-argument-asserts"]],
                excludeFromDocumentation: true),
        Example("XCTAssert(foo == bar)",
                configuration: ["matchers": ["two-argument-asserts"]],
                excludeFromDocumentation: true),

        // Skip if one operand might be a type or a tuple
        Example("XCTAssert(foo.self == bar)"),
        Example("XCTAssertTrue(type(of: foo) != Int.self)"),
        Example("XCTAssertTrue(a == (1, 3, 5)"),

        // Identity comparisons with valid usage
        Example("XCTAssertIdentical(foo, bar)"),
        Example("XCTAssertNotIdentical(foo, bar)"),
        Example("XCTAssert(foo.self === bar.self)"),
    ]

    static let triggeringExamples = #examples([
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
        "↓XCTAssertEqual(false, false)",

        // Equality with `==`
        "↓XCTAssert(foo == bar)",
        "↓XCTAssertTrue(   foo  ==   bar  )",
        "↓XCTAssertFalse(1 == foo)",
        "↓XCTAssert(foo == bar, \"toto\")",

        // Inequality with `!=`
        "↓XCTAssert(foo != bar)",
        "↓XCTAssertTrue(   foo  !=   bar  )",
        "↓XCTAssertFalse(1 != foo)",
        "↓XCTAssert(foo != bar, \"toto\")",

        // Identity with `===`
        "↓XCTAssert(foo === bar)",
        "↓XCTAssertTrue(   foo  ===   bar  )",
        "↓XCTAssertFalse(bar === foo)",
        "↓XCTAssert(foo === bar, \"toto\")",

        // Non-identity with `!==`
        "↓XCTAssert(foo !== bar)",
        "↓XCTAssertTrue(   foo  !==   bar  )",
        "↓XCTAssertFalse(bar !== foo)",
        "↓XCTAssert(foo !== bar, \"toto\")",

        // Comparison with `nil`
        "↓XCTAssert(  foo   ==  nil)",
        "↓XCTAssert(nil == foo",
        "↓XCTAssertTrue(  foo   !=  nil)",
        "↓XCTAssertFalse(nil != foo",
        "↓XCTAssert(foo == nil, \"toto\")",
    ])
}
