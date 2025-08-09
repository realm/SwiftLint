internal struct FunctionNameWhitespaceRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("func abc(lhs: Int, rhs: Int) -> Int {}"),
        Example(
            "func abc<T>(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),
        Example(
            "func abc <T>(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_space"]
        ),
        Example(
            "func abc<T> (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "trailing_space"]
        ),
        Example(
            "func abc <T>(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_space"]
        ),
        Example(
            "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_space"]
        ),

        Example(
            "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "trailing_space"]
        ),
        Example(
            "func abc <T> (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_trailing_space"]
        ),
        Example("func /* comment */ abc(lhs: Int, rhs: Int) -> Int {}"),
        Example("func /* comment */  abc(lhs: Int, rhs: Int) -> Int {}"),
        Example("func abc /* comment */ (lhs: Int, rhs: Int) -> Int {}"),
        Example(
            "func abc /* comment */ <T>(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),
        Example(
            "func abc<T> /* comment */ (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),
        Example(
            "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),

        Example("""
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ),
        Example("""
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_trailing_space"]
               ),
        Example("""
        func foo /* comment */ <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_trailing_space"]
               ),
    ]

    static let triggeringExamples: [Example] = [
        Example("func↓  name(lhs: A, rhs: A) -> A {}"),
        Example("func name↓ (lhs: A, rhs: A) -> A {}"),
        Example("func↓  name↓ (lhs: A, rhs: A) -> A {}"),
        Example("func name↓ <T>(lhs: Int, rhs: Int) -> Int {}"),
        Example(
            "func name↓ /* comment */  <T>↓  /* comment */  (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),
        Example(
            "func name /* comment */ /* comment */  <T>↓  /* comment */  (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ),
        Example("""
        func foo<
           T
        >↓ (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ),
        Example("""
        func foo↓ <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ),
        Example("""
        func foo↓ <
          T
        >↓ (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ),
        Example(
            "func abc <T>↓ (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_space"]
        ),
        Example("""
        func foo <
        T
        >↓ (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_space"]
               ),
        Example(
            "func abc↓ <T> (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "trailing_space"]
        ),
        Example("""
        func foo↓ <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "trailing_space"]
               ),
        Example(
            "func abc↓<T> (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_trailing_space"]
        ),
        Example(
            "func abc <T>↓(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_trailing_space"]
        ),
        Example(
            "func abc↓<T>↓(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_trailing_space"]
        ),
        Example("""
        func foo↓ /* comment */  <
        T
        >↓  (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_trailing_space"]
               ),
    ]

    static let corrections: [Example: Example] = [
        Example(
            "func name /* comment */  <T>  /* comment */  (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ): Example(
            "func name /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}"
        ),
        Example(
            "func name /* comment */  <T>(lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "no_space"]
        ): Example(
            "func name /* comment */ <T>(lhs: Int, rhs: Int) -> Int {}"
        ),

        Example("""
        func foo<
           T
        > (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ): Example("""
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """),
        Example("""
        func foo <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ): Example("""
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """),
        Example("""
        func foo <
           T
        > (
           param0: Int,
           param1: Bool,
           param2: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "no_space"]
               ): Example("""
        func foo<
           T
        >(
           param0: Int,
           param1: Bool,
           param2: [String]
        ) { }
        """),
        Example("func  name (lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
        Example("func  name(lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
        Example("func   name(lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
        Example("func name (lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
        Example("func name <T>(lhs: Int) -> Int {}"): Example("func name<T>(lhs: Int) -> Int {}"),
        Example(
            "func abc <T> (lhs1: Int, rhs1: Int) -> Int {}",
            configuration: ["generic_spacing": "leading_space"]
        ): Example(
            "func abc <T>(lhs1: Int, rhs1: Int) -> Int {}"
        ),
        Example("""
        func foo <
           T
        > (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_space"]
               ): Example("""
        func foo <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """),
        Example(
            "func abc <T> (lhs: Int, rhs: Int) -> Int {}",
            configuration: ["generic_spacing": "trailing_space"]
        ): Example(
            "func abc<T> (lhs: Int, rhs: Int) -> Int {}"
        ),
        Example("""
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "trailing_space"]
               ): Example("""
        func foo<
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """),
        Example("""
        func foo  <
        T
        >  (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
                configuration: ["generic_spacing": "leading_trailing_space"]
               ): Example("""
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """),
    ]
}
