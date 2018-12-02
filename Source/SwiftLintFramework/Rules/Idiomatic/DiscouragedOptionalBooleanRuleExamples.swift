internal struct DiscouragedOptionalBooleanRuleExamples {
    static let nonTriggeringExamples = [
        // Global variable
        "var foo: Bool",
        "var foo: [String: Bool]",
        "var foo: [Bool]",
        "let foo: Bool = true",
        "let foo: Bool = false",
        "let foo: [String: Bool] = [:]",
        "let foo: [Bool] = []",

        // Computed get variable
        "var foo: Bool { return true }",
        "let foo: Bool { return false }()",

        // Free function return
        "func foo() -> Bool {}",
        "func foo() -> [String: Bool] {}",
        "func foo() -> ([Bool]) -> String {}",

        // Free function parameter
        "func foo(input: Bool = true) {}",
        "func foo(input: [String: Bool] = [:]) {}",
        "func foo(input: [Bool] = []) {}",

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
        "var foo: ↓Bool?",
        "var foo: [String: ↓Bool?]",
        "var foo: [↓Bool?]",
        "let foo: ↓Bool? = nil",
        "let foo: [String: ↓Bool?] = [:]",
        "let foo: [↓Bool?] = []",
        "let foo = ↓Optional.some(false)",
        "let foo = ↓Optional.some(true)",

        // Computed Get Variable
        "var foo: ↓Bool? { return nil }",
        "let foo: ↓Bool? { return nil }()",

        // Free function return
        "func foo() -> ↓Bool? {}",
        "func foo() -> [String: ↓Bool?] {}",
        "func foo() -> [↓Bool?] {}",
        "static func foo() -> ↓Bool? {}",
        "static func foo() -> [String: ↓Bool?] {}",
        "static func foo() -> [↓Bool?] {}",
        "func foo() -> (↓Bool?) -> String {}",
        "func foo() -> ([Int]) -> ↓Bool? {}",

        // Free function parameter
        "func foo(input: ↓Bool?) {}",
        "func foo(input: [String: ↓Bool?]) {}",
        "func foo(input: [↓Bool?]) {}",
        "static func foo(input: ↓Bool?) {}",
        "static func foo(input: [String: ↓Bool?]) {}",
        "static func foo(input: [↓Bool?]) {}",

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
        wrapExample("enum", "static func foo(input: [↓Bool?]) {}")
    ]
}

// MARK: - Private

private func wrapExample(_ type: String, _ test: String) -> String {
    return "\(type) Foo {\n\t\(test)\n}"
}
