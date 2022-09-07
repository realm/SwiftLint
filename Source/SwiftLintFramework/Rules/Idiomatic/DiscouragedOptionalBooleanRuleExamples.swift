internal struct DiscouragedOptionalBooleanRuleExamples {
    static let nonTriggeringExamples = [
        // Global variable
        Example("var foo: Bool"),
        Example("var foo: [String: Bool]"),
        Example("var foo: [Bool]"),
        Example("let foo: Bool = true"),
        Example("let foo: Bool = false"),
        Example("let foo: [String: Bool] = [:]"),
        Example("let foo: [Bool] = []"),

        // Computed get variable
        Example("var foo: Bool { return true }"),
        Example("let foo: Bool { return false }()"),

        // Free function return
        Example("func foo() -> Bool {}"),
        Example("func foo() -> [String: Bool] {}"),
        Example("func foo() -> ([Bool]) -> String {}"),

        // Free function parameter
        Example("func foo(input: Bool = true) {}"),
        Example("func foo(input: [String: Bool] = [:]) {}"),
        Example("func foo(input: [Bool] = []) {}"),

        // Method return
        wrapExample("class", "func foo() -> Bool {}"),
        wrapExample("class", "func foo() -> [String: Bool] {}"),
        wrapExample("class", "func foo() -> ([Bool]) -> String {}"),

        wrapExample("struct", "func foo() -> Bool {}"),
        wrapExample("struct", "func foo() -> [String: Bool] {}"),
        wrapExample("struct", "func foo() -> ([Bool]) -> String {}"),

        wrapExample("enum", "func foo() -> Bool {}"),
        wrapExample("enum", "func foo() -> [String: Bool] {}"),
        wrapExample("enum", "func foo() -> ([Bool]) -> String {}"),

        // Method parameter
        wrapExample("class", "func foo(input: Bool = true) {}"),
        wrapExample("class", "func foo(input: [String: Bool] = [:]) {}"),
        wrapExample("class", "func foo(input: [Bool] = []) {}"),

        wrapExample("struct", "func foo(input: Bool = true) {}"),
        wrapExample("struct", "func foo(input: [String: Bool] = [:]) {}"),
        wrapExample("struct", "func foo(input: [Bool] = []) {}"),

        wrapExample("enum", "func foo(input: Bool = true) {}"),
        wrapExample("enum", "func foo(input: [String: Bool] = [:]) {}"),
        wrapExample("enum", "func foo(input: [Bool] = []) {}")
    ]

    static let triggeringExamples = [
        // Global variable
        Example("var foo: ↓Bool?"),
        Example("var foo: [String: ↓Bool?]"),
        Example("var foo: [↓Bool?]"),
        Example("let foo: ↓Bool? = nil"),
        Example("let foo: [String: ↓Bool?] = [:]"),
        Example("let foo: [↓Bool?] = []"),
        Example("let foo = ↓Optional.some(false)"),
        Example("let foo = ↓Optional.some(true)"),

        // Computed Get Variable
        Example("var foo: ↓Bool? { return nil }"),
        Example("let foo: ↓Bool? { return nil }()"),

        // Free function return
        Example("func foo() -> ↓Bool? {}"),
        Example("func foo() -> [String: ↓Bool?] {}"),
        Example("func foo() -> [↓Bool?] {}"),
        Example("static func foo() -> ↓Bool? {}"),
        Example("static func foo() -> [String: ↓Bool?] {}"),
        Example("static func foo() -> [↓Bool?] {}"),
        Example("func foo() -> (↓Bool?) -> String {}"),
        Example("func foo() -> ([Int]) -> ↓Bool? {}"),

        // Free function parameter
        Example("func foo(input: ↓Bool?) {}"),
        Example("func foo(input: [String: ↓Bool?]) {}"),
        Example("func foo(input: [↓Bool?]) {}"),
        Example("static func foo(input: ↓Bool?) {}"),
        Example("static func foo(input: [String: ↓Bool?]) {}"),
        Example("static func foo(input: [↓Bool?]) {}"),

        // Instance variable
        wrapExample("class", "var foo: ↓Bool?"),
        wrapExample("class", "var foo: [String: ↓Bool?]"),
        wrapExample("class", "let foo: ↓Bool? = nil"),
        wrapExample("class", "let foo: [String: ↓Bool?] = [:]"),
        wrapExample("class", "let foo: [↓Bool?] = []"),

        wrapExample("struct", "var foo: ↓Bool?"),
        wrapExample("struct", "var foo: [String: ↓Bool?]"),
        wrapExample("struct", "let foo: ↓Bool? = nil"),
        wrapExample("struct", "let foo: [String: ↓Bool?] = [:]"),
        wrapExample("struct", "let foo: [↓Bool?] = []"),

        // Instance computed variable
        wrapExample("class", "var foo: ↓Bool? { return nil }"),
        wrapExample("class", "let foo: ↓Bool? { return nil }()"),

        wrapExample("struct", "var foo: ↓Bool? { return nil }"),
        wrapExample("struct", "let foo: ↓Bool? { return nil }()"),

        wrapExample("enum", "var foo: ↓Bool? { return nil }"),
        wrapExample("enum", "let foo: ↓Bool? { return nil }()"),

        // Method return
        wrapExample("class", "func foo() -> ↓Bool? {}"),
        wrapExample("class", "func foo() -> [String: ↓Bool?] {}"),
        wrapExample("class", "func foo() -> [↓Bool?] {}"),
        wrapExample("class", "static func foo() -> ↓Bool? {}"),
        wrapExample("class", "static func foo() -> [String: ↓Bool?] {}"),
        wrapExample("class", "static func foo() -> [↓Bool?] {}"),
        wrapExample("class", "func foo() -> (↓Bool?) -> String {}"),
        wrapExample("class", "func foo() -> ([Int]) -> ↓Bool? {}"),

        wrapExample("struct", "func foo() -> ↓Bool? {}"),
        wrapExample("struct", "func foo() -> [String: ↓Bool?] {}"),
        wrapExample("struct", "func foo() -> [↓Bool?] {}"),
        wrapExample("struct", "static func foo() -> ↓Bool? {}"),
        wrapExample("struct", "static func foo() -> [String: ↓Bool?] {}"),
        wrapExample("struct", "static func foo() -> [↓Bool?] {}"),
        wrapExample("struct", "func foo() -> (↓Bool?) -> String {}"),
        wrapExample("struct", "func foo() -> ([Int]) -> ↓Bool? {}"),

        wrapExample("enum", "func foo() -> ↓Bool? {}"),
        wrapExample("enum", "func foo() -> [String: ↓Bool?] {}"),
        wrapExample("enum", "func foo() -> [↓Bool?] {}"),
        wrapExample("enum", "static func foo() -> ↓Bool? {}"),
        wrapExample("enum", "static func foo() -> [String: ↓Bool?] {}"),
        wrapExample("enum", "static func foo() -> [↓Bool?] {}"),
        wrapExample("enum", "func foo() -> (↓Bool?) -> String {}"),
        wrapExample("enum", "func foo() -> ([Int]) -> ↓Bool? {}"),

        // Method parameter
        wrapExample("class", "func foo(input: ↓Bool?) {}"),
        wrapExample("class", "func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("class", "func foo(input: [↓Bool?]) {}"),
        wrapExample("class", "static func foo(input: ↓Bool?) {}"),
        wrapExample("class", "static func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("class", "static func foo(input: [↓Bool?]) {}"),

        wrapExample("struct", "func foo(input: ↓Bool?) {}"),
        wrapExample("struct", "func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("struct", "func foo(input: [↓Bool?]) {}"),
        wrapExample("struct", "static func foo(input: ↓Bool?) {}"),
        wrapExample("struct", "static func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("struct", "static func foo(input: [↓Bool?]) {}"),

        wrapExample("enum", "func foo(input: ↓Bool?) {}"),
        wrapExample("enum", "func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("enum", "func foo(input: [↓Bool?]) {}"),
        wrapExample("enum", "static func foo(input: ↓Bool?) {}"),
        wrapExample("enum", "static func foo(input: [String: ↓Bool?]) {}"),
        wrapExample("enum", "static func foo(input: [↓Bool?]) {}"),

        // Optional chaining
        Example("_ = ↓Bool?.values()")
    ]
}

// MARK: - Private

private func wrapExample(_ type: String, _ test: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("\(type) Foo {\n\t\(test)\n}", file: file, line: line)
}
