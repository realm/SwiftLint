internal struct FunctionNameWhitespaceRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        "func abc(lhs: Int, rhs: Int) -> Int {}",
        "func <| (lhs: Int, rhs: Int) -> Int {}",
        "func <|< <A>(lhs: A, rhs: A) -> A {}",
        "func <| /* comment */ (lhs: Int, rhs: Int) -> Int {}",
        "func <|< /* comment */ <A>(lhs: A, rhs: A) -> A {}",
        "func <|< <A> /* comment */ (lhs: A, rhs: A) -> A {}",
        "func <| /* comment */ <T> /* comment */ (lhs: T, rhs: T) -> T {}",
        "func abc<T>(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "no_space"]),
        "func abc <T>(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_space"]),
        "func abc<T> (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "trailing_space"]),
        "func abc <T>(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_space"]),
        "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "leading_space"]),

        "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "trailing_space"]),
        "func abc <T> (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_trailing_space"]),
        "func /* comment */ abc(lhs: Int, rhs: Int) -> Int {}",
        "func /* comment */  abc(lhs: Int, rhs: Int) -> Int {}",
        "func abc /* comment */ (lhs: Int, rhs: Int) -> Int {}",
        "func abc /* comment */ <T>(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "no_space"]),
        "func abc<T> /* comment */ (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "no_space"]),
        "func abc /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "no_space"]),

        """
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]),
        """
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_trailing_space"]),
        """
        func foo /* comment */ <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_trailing_space"]),
    ])

    static let triggeringExamples: [Example] = #examples([
        "func↓  name(lhs: A, rhs: A) -> A {}",
        "func name↓ (lhs: A, rhs: A) -> A {}",
        "func↓  name↓ (lhs: A, rhs: A) -> A {}",
        "func <|↓(lhs: Int, rhs: Int) -> Int {}",
        "func <|<↓<A>(lhs: A, rhs: A) -> A {}",
        "func <|↓  (lhs: Int, rhs: Int) -> Int {}",
        "func <|<↓  <A>(lhs: A, rhs: A) -> A {}",
        "func <|↓/* comment */  (lhs: Int, rhs: Int) -> Int {}",
        "func <|<↓/* comment */  <A>(lhs: A, rhs: A) -> A {}",
        "func <|< <A>↓/* comment */  (lhs: A, rhs: A) -> A {}",
        "func name↓ <T>(lhs: Int, rhs: Int) -> Int {}",
        "func name↓ /* comment */  <T>↓  /* comment */  (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "no_space"]),
        "func name /* comment */ /* comment */  <T>↓  /* comment */  (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "no_space"]),
        """
        func foo<
           T
        >↓ (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]),
        """
        func foo↓ <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]),
        """
        func foo↓ <
          T
        >↓ (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]),
        "func abc <T>↓ (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_space"]),
        """
        func foo <
        T
        >↓ (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_space"]),
        "func abc↓ <T> (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "trailing_space"]),
        """
        func foo↓ <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "trailing_space"]),
        "func abc↓<T> (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_trailing_space"]),
        "func abc <T>↓(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_trailing_space"]),
        "func abc↓<T>↓(lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "leading_trailing_space"]),
        """
        func foo↓ /* comment */  <
        T
        >↓  (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_trailing_space"]),
    ])

    static let corrections: [Example: Example] = #corrections([
        "func name /* comment */  <T>  /* comment */  (lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "no_space"]):
            "func name /* comment */ <T> /* comment */ (lhs: Int, rhs: Int) -> Int {}",
        "func name /* comment */  <T>(lhs: Int, rhs: Int) -> Int {}"
            .configuration(["generic_spacing": "no_space"]):
            "func name /* comment */ <T>(lhs: Int, rhs: Int) -> Int {}",

        """
        func foo<
           T
        > (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]): """
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
        """
        func foo <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]): """
        func foo<
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
        """
        func foo <
           T
        > (
           param0: Int,
           param1: Bool,
           param2: [String]
        ) { }
        """.configuration(["generic_spacing": "no_space"]): """
        func foo<
           T
        >(
           param0: Int,
           param1: Bool,
           param2: [String]
        ) { }
        """,
        "func  name (lhs: A, rhs: A) -> A {}": "func name(lhs: A, rhs: A) -> A {}",
        "func  name(lhs: A, rhs: A) -> A {}": "func name(lhs: A, rhs: A) -> A {}",
        "func   name(lhs: A, rhs: A) -> A {}": "func name(lhs: A, rhs: A) -> A {}",
        "func name (lhs: A, rhs: A) -> A {}": "func name(lhs: A, rhs: A) -> A {}",
        "func <|(lhs: Int, rhs: Int) -> Int {}": "func <| (lhs: Int, rhs: Int) -> Int {}",
        "func <|<<A>(lhs: A, rhs: A) -> A {}": "func <|< <A>(lhs: A, rhs: A) -> A {}",
        "func <|  (lhs: Int, rhs: Int) -> Int {}": "func <| (lhs: Int, rhs: Int) -> Int {}",
        "func <|<  <A>(lhs: A, rhs: A) -> A {}": "func <|< <A>(lhs: A, rhs: A) -> A {}",
        "func <|/* comment */  (lhs: Int, rhs: Int) -> Int {}":
            "func <| /* comment */ (lhs: Int, rhs: Int) -> Int {}",
        "func <|</* comment */  <A>(lhs: A, rhs: A) -> A {}":
            "func <|< /* comment */ <A>(lhs: A, rhs: A) -> A {}",
        "func <|< <A>/* comment */  (lhs: A, rhs: A) -> A {}":
            "func <|< <A> /* comment */ (lhs: A, rhs: A) -> A {}",
        "func name <T>(lhs: Int) -> Int {}": "func name<T>(lhs: Int) -> Int {}",
        "func abc <T> (lhs1: Int, rhs1: Int) -> Int {}".configuration(["generic_spacing": "leading_space"]):
            "func abc <T>(lhs1: Int, rhs1: Int) -> Int {}",
        """
        func foo <
           T
        > (
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_space"]): """
        func foo <
           T
        >(
           param1: Int,
           param2: Bool,
           param3: [String]
        ) { }
        """,
        "func abc <T> (lhs: Int, rhs: Int) -> Int {}".configuration(["generic_spacing": "trailing_space"]):
            "func abc<T> (lhs: Int, rhs: Int) -> Int {}",
        """
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "trailing_space"]): """
        func foo<
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
        """
        func foo  <
        T
        >  (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """.configuration(["generic_spacing": "leading_trailing_space"]): """
        func foo <
        T
        > (
            param1: Int,
            param2: Bool,
            param3: [String]
        ) { }
        """,
    ])
}
