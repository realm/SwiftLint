internal struct DiscouragedOptionalCollectionExamples {
    static let nonTriggeringExamples = [
        // Global variable
        Example("var foo: [Int]"),
        Example("var foo: [String: Int]"),
        Example("var foo: Set<String>"),
        Example("var foo: [String: [String: Int]]"),
        Example("let foo: [Int] = []"),
        Example("let foo: [String: Int] = [:]"),
        Example("let foo: Set<String> = []"),
        Example("let foo: [String: [String: Int]] = [:]"),

        // Computed get variable
        Example("var foo: [Int] { return [] }"),

        // Free function return
        Example("func foo() -> [Int] {}"),
        Example("func foo() -> [String: String] {}"),
        Example("func foo() -> Set<Int> {}"),
        Example("func foo() -> ([Int]) -> String {}"),

        // Free function parameter
        Example("func foo(input: [String] = []) {}"),
        Example("func foo(input: [String: String] = [:]) {}"),
        Example("func foo(input: Set<String> = []) {}"),

        // Method return
        wrapExample("class", "func foo() -> [Int] {}"),
        wrapExample("class", "func foo() -> [String: String] {}"),
        wrapExample("class", "func foo() -> Set<Int> {}"),
        wrapExample("class", "func foo() -> ([Int]) -> String {}"),

        wrapExample("struct", "func foo() -> [Int] {}"),
        wrapExample("struct", "func foo() -> [String: String] {}"),
        wrapExample("struct", "func foo() -> Set<Int> {}"),
        wrapExample("struct", "func foo() -> ([Int]) -> String {}"),

        wrapExample("enum", "func foo() -> [Int] {}"),
        wrapExample("enum", "func foo() -> [String: String] {}"),
        wrapExample("enum", "func foo() -> Set<Int> {}"),
        wrapExample("enum", "func foo() -> ([Int]) -> String {}"),

        // Method parameter
        wrapExample("class", "func foo(input: [String] = []) {}"),
        wrapExample("class", "func foo(input: [String: String] = [:]) {}"),
        wrapExample("class", "func foo(input: Set<String> = []) {}"),

        wrapExample("struct", "func foo(input: [String] = []) {}"),
        wrapExample("struct", "func foo(input: [String: String] = [:]) {}"),
        wrapExample("struct", "func foo(input: Set<String> = []) {}"),

        wrapExample("enum", "func foo(input: [String] = []) {}"),
        wrapExample("enum", "func foo(input: [String: String] = [:]) {}"),
        wrapExample("enum", "func foo(input: Set<String> = []) {}")
    ]

    static let triggeringExamples = [
        // Global variable
        Example("↓var foo: [Int]?"),
        Example("↓var foo: [String: Int]?"),
        Example("↓var foo: Set<String>?"),
        Example("↓let foo: [Int]? = nil"),
        Example("↓let foo: [String: Int]? = nil"),
        Example("↓let foo: Set<String>? = nil"),

        // Computed Get Variable
        Example("↓var foo: [Int]? { return nil }"),
        Example("↓let foo: [Int]? { return nil }()"),

        // Free function return
        Example("func ↓foo() -> [T]? {}"),
        Example("func ↓foo() -> [String: String]? {}"),
        Example("func ↓foo() -> [String: [String: String]]? {}"),
        Example("func ↓foo() -> [String: [String: String]?] {}"),
        Example("func ↓foo() -> Set<Int>? {}"),
        Example("static func ↓foo() -> [T]? {}"),
        Example("static func ↓foo() -> [String: String]? {}"),
        Example("static func ↓foo() -> [String: [String: String]]? {}"),
        Example("static func ↓foo() -> [String: [String: String]?] {}"),
        Example("static func ↓foo() -> Set<Int>? {}"),
        Example("func ↓foo() -> ([Int]?) -> String {}"),
        Example("func ↓foo() -> ([Int]) -> [String]? {}"),

        // Free function parameter
        Example("func foo(↓input: [String: String]?) {}"),
        Example("func foo(↓input: [String: [String: String]]?) {}"),
        Example("func foo(↓input: [String: [String: String]?]) {}"),
        Example("func foo(↓↓input: [String: [String: String]?]?) {}"),
        Example("func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        Example("func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),
        Example("static func foo(↓input: [String: String]?) {}"),
        Example("static func foo(↓input: [String: [String: String]]?) {}"),
        Example("static func foo(↓input: [String: [String: String]?]) {}"),
        Example("static func foo(↓↓input: [String: [String: String]?]?) {}"),
        Example("static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        Example("static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),

        // Instance variable
        wrapExample("class", "↓var foo: [Int]?"),
        wrapExample("class", "↓var foo: [String: Int]?"),
        wrapExample("class", "↓var foo: Set<String>?"),
        wrapExample("class", "↓let foo: [Int]? = nil"),
        wrapExample("class", "↓let foo: [String: Int]? = nil"),
        wrapExample("class", "↓let foo: Set<String>? = nil"),

        wrapExample("struct", "↓var foo: [Int]?"),
        wrapExample("struct", "↓var foo: [String: Int]?"),
        wrapExample("struct", "↓var foo: Set<String>?"),
        wrapExample("struct", "↓let foo: [Int]? = nil"),
        wrapExample("struct", "↓let foo: [String: Int]? = nil"),
        wrapExample("struct", "↓let foo: Set<String>? = nil"),

        // Instance computed variable
        wrapExample("class", "↓var foo: [Int]? { return nil }"),
        wrapExample("class", "↓let foo: [Int]? { return nil }()"),
        wrapExample("class", "↓var foo: Set<String>? { return nil }"),
        wrapExample("class", "↓let foo: Set<String>? { return nil }()"),

        wrapExample("struct", "↓var foo: [Int]? { return nil }"),
        wrapExample("struct", "↓let foo: [Int]? { return nil }()"),
        wrapExample("struct", "↓var foo: Set<String>? { return nil }"),
        wrapExample("struct", "↓let foo: Set<String>? { return nil }()"),

        wrapExample("enum", "↓var foo: [Int]? { return nil }"),
        wrapExample("enum", "↓let foo: [Int]? { return nil }()"),
        wrapExample("enum", "↓var foo: Set<String>? { return nil }"),
        wrapExample("enum", "↓let foo: Set<String>? { return nil }()"),

        // Method return
        wrapExample("class", "func ↓foo() -> [T]? {}"),
        wrapExample("class", "func ↓foo() -> [String: String]? {}"),
        wrapExample("class", "func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("class", "func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("class", "func ↓foo() -> Set<Int>? {}"),
        wrapExample("class", "static func ↓foo() -> [T]? {}"),
        wrapExample("class", "static func ↓foo() -> [String: String]? {}"),
        wrapExample("class", "static func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("class", "static func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("class", "static func ↓foo() -> Set<Int>? {}"),
        wrapExample("class", "func ↓foo() -> ([Int]?) -> String {}"),
        wrapExample("class", "func ↓foo() -> ([Int]) -> [String]? {}"),

        wrapExample("struct", "func ↓foo() -> [T]? {}"),
        wrapExample("struct", "func ↓foo() -> [String: String]? {}"),
        wrapExample("struct", "func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("struct", "func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("struct", "func ↓foo() -> Set<Int>? {}"),
        wrapExample("struct", "static func ↓foo() -> [T]? {}"),
        wrapExample("struct", "static func ↓foo() -> [String: String]? {}"),
        wrapExample("struct", "static func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("struct", "static func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("struct", "static func ↓foo() -> Set<Int>? {}"),
        wrapExample("struct", "func ↓foo() -> ([Int]?) -> String {}"),
        wrapExample("struct", "func ↓foo() -> ([Int]) -> [String]? {}"),

        wrapExample("enum", "func ↓foo() -> [T]? {}"),
        wrapExample("enum", "func ↓foo() -> [String: String]? {}"),
        wrapExample("enum", "func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("enum", "func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("enum", "func ↓foo() -> Set<Int>? {}"),
        wrapExample("enum", "static func ↓foo() -> [T]? {}"),
        wrapExample("enum", "static func ↓foo() -> [String: String]? {}"),
        wrapExample("enum", "static func ↓foo() -> [String: [String: String]]? {}"),
        wrapExample("enum", "static func ↓foo() -> [String: [String: String]?] {}"),
        wrapExample("enum", "static func ↓foo() -> Set<Int>? {}"),
        wrapExample("enum", "func ↓foo() -> ([Int]?) -> String {}"),
        wrapExample("enum", "func ↓foo() -> ([Int]) -> [String]? {}"),

        // Method parameter
        wrapExample("class", "func foo(↓input: [String: String]?) {}"),
        wrapExample("class", "func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("class", "func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("class", "func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("class", "func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("class", "func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),
        wrapExample("class", "static func foo(↓input: [String: String]?) {}"),
        wrapExample("class", "static func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("class", "static func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("class", "static func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("class", "static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("class", "static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),

        wrapExample("struct", "func foo(↓input: [String: String]?) {}"),
        wrapExample("struct", "func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("struct", "func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("struct", "func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("struct", "func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("struct", "func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),
        wrapExample("struct", "static func foo(↓input: [String: String]?) {}"),
        wrapExample("struct", "static func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("struct", "static func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("struct", "static func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("struct", "static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("struct", "static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),

        wrapExample("enum", "func foo(↓input: [String: String]?) {}"),
        wrapExample("enum", "func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("enum", "func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("enum", "func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("enum", "func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("enum", "func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]"),
        wrapExample("enum", "static func foo(↓input: [String: String]?) {}"),
        wrapExample("enum", "static func foo(↓input: [String: [String: String]]?) {}"),
        wrapExample("enum", "static func foo(↓input: [String: [String: String]?]) {}"),
        wrapExample("enum", "static func foo(↓↓input: [String: [String: String]?]?) {}"),
        wrapExample("enum", "static func foo<K, V>(_ dict1: [K: V], ↓_ dict2: [K: V]?) -> [K: V]"),
        wrapExample("enum", "static func foo<K, V>(dict1: [K: V], ↓dict2: [K: V]?) -> [K: V]")
    ]
}

// MARK: - Private

private func wrapExample(_ type: String, _ test: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
        \(type) Foo {
            \(test)
        }
        """, file: file, line: line)
}
