import SwiftLintCore

// swiftlint:disable file_length

struct MultilineCallArgumentsRuleExamples { // swiftlint:disable:this type_body_length
    static let nonTriggeringExamples: [Example] = #examples([
        // MARK: - All configuration options shown
        """
        foo(
            param1: 1,
            param2: false,
            param3: []
        )
        """.asExample(configuration: ["allows_single_line": false]),
        """
        foo(param1: 1, param2: false)
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        foo(
        \tparam1: 1,
        \tparam2: false
        )
        """.asExample(configuration: ["allows_single_line": false]),

        // MARK: - Baseline: multi-line OK
        """
        foo(param1: 1,
            param2: false,
            param3: [])
        """.asExample(configuration: ["max_number_of_single_line_parameters": 1]),
        """
        func foo(one: [Int], animated: Bool) {}
        add(one: [
            1,
            2,
            3
        ], animated: true)
        """,
        """
        foo(
            param1: 1,
            param2: 2,
            param3: 3
        )
        """.asExample(configuration: ["allows_single_line": false]),

        // MARK: - Baseline: single-line OK

        "foo(param1: 1, param2: false)".asExample(configuration: ["max_number_of_single_line_parameters": 2]
                                                 ),

        "Enum.foo(param1: 1, param2: false)".asExample(configuration: ["max_number_of_single_line_parameters": 2]
                                                      ),

        // allows_single_line=false does NOT affect 0/1-arg calls
        "foo()".asExample(configuration: ["allows_single_line": false]),
        "foo(param1: 1)".asExample(configuration: ["allows_single_line": false]),
        "Enum.foo(param1: 1)".asExample(configuration: ["allows_single_line": false]),

        // MARK: - Unlabeled / mixed arguments
        "foo(1, 2)".asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2)".asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2, c: 3)".asExample(configuration: ["max_number_of_single_line_parameters": 3]),

        // MARK: - Enum-case constructor calls are normal calls (stable by declaring the enum)
        """
        enum EnumCase {
            case first(one: Int, two: Int, three: Int, four: Int)
        }
        EnumCase.first(one: 1, two: 2, three: 3, four: 4)
        """.asExample(configuration: ["allows_single_line": true]),
        """
        enum EnumCase {
            case first(one: Int, two: Int, three: Int, four: Int)
        }
        let test = EnumCase.first(
            one: 1,
            two: 2,
            three: 3,
            four: 4
        )
        """.asExample(configuration: ["allows_single_line": false]),

        // MARK: - Trailing closures are ignored by this rule (args-only)
        // Single-line args still use max_number_of_single_line_parameters
        """
        foo(a: 1, b: 2) { value in
            print(value)
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        // Multi-line args remain valid regardless of closure placement
        """
        foo(
            a: 1,
            b: 2
        ) { value in
            print(value)
        }
        """.asExample(configuration: ["allows_single_line": false]),
        """
        foo(
            a: 1,
            b: 2
        )
        { value in
            print(value)
        }
        """.asExample(configuration: ["allows_single_line": false]),
        // No-parens form: no arguments list -> never violates
        """
        foo { value in
            print(value)
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 1]),
        // Multiple trailing closures: still args-only
        """
        foo(a: 1, b: 2) { _ in
            print("main")
        } trailing: { _ in
            print("extra")
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        foo(with: { _ in
            9_999
        }, and: { _ in
            nil
        })
        """,

        // MARK: - Trivia / comments
        """
        foo(
            a: 1,
            // comment
            b: 2,
            c: 3
        )
        """,
        // Note: arguments start on the same line, so this is treated as a single-line-args call;
        // the comma-newline check applies only when argument start lines are already split.
        """
        foo(
            a: (1, 2), b: 3
        )
        """,
        """
        foo(
            a: (1, 2),
            b: 3
        )
        """.asExample(configuration: ["allows_single_line": false]),
        """
        foo(
            a: 1, // comment
            b: 2,
            c: 3
        )
        """,
        """
        enum EnumCase {
            case caseOne(Int, Int, Int, Int)
        }
        let enumCase: EnumCase = .caseOne(
            1,
            2,
            3,
            4
        )
        if case let .caseOne(_, _, three, _) = enumCase {
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        enum EnumCase {
            case caseOne(one: Int, two: Int, three: Int, four: Int)
        }
        let enumCase: EnumCase = .caseOne(
            one: 1,
            two: 2,
            three: 3,
            four: 4
        )
        switch enumCase {
        case let .caseOne(one: _, two: _, three: three, four: _):
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        enum EnumCase { case caseOne(Int, Int, Int, Int) }
        let array: [EnumCase] = [
            .caseOne(
                1,
                2,
                3,
                4
            )
        ]
        for case let .caseOne(_, _, three, _) in array {
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        enum EnumCase {
            case caseOne(Int, Int, Int, Int)
        }
        let enumCase: EnumCase = .caseOne(
            1,
            2,
            3,
            4
        )
        guard case let .caseOne(_, _, three, _) = enumCase else { return }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        enum EnumCase {
            case caseOne(Int, Int, Int, Int)
        }
        let enumCase: EnumCase = .caseOne(
            1,
            2,
            3,
            4
        )
        while case let .caseOne(_, _, three, _) = enumCase {
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // MARK: - Pattern matching MUST be ignored: catch patterns
        """
        enum EnumCase: Error {
            case caseOne(Int, Int, Int, Int)
        }

        func mayThrow() throws {
        }

        do {
            try mayThrow()
        } catch let EnumCase.caseOne(_, _, three, _) {
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        """
        enum EnumCase: Error {
            case caseOne(one: Int, two: Int, three: Int, four: Int)
        }

        func mayThrow() throws {
        }

        do {
            try mayThrow()
        } catch let EnumCase.caseOne(one: _, two: _, three: three, four: _) {
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // MARK: - Regular calls near patterns are still linted
        """
        func foo(a: Int, b: Int, c: Int) -> Int { a + b + c }
        enum EnumCase { case caseOne(Int, Int, Int, Int) }

        if case let .caseOne(_, _, _, _) = EnumCase.caseOne(
            1,
            2,
            3,
            4
        ) {
            _ = foo(
                a: 1,
                b: 2,
                c: 3
            )
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        // MARK: - Pattern matching MUST be ignored: enum-case patterns with literal subpatterns
        """
        enum EnumCase {
            case caseOne(Int, Int, Int, Int)
        }

        // Real call is written multi-line to avoid noise for max=2
        let enumCase: EnumCase = .caseOne(
            0,
            0,
            0,
            0
        )

        // This is a PATTERN, not a call, and must be ignored even though it looks like `.caseOne(1,2,3,4)`
        if case .caseOne(1, 2, 3, 4) = enumCase {
            // no-op
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        """
        enum EnumCase {
            case caseOne(one: Int, two: Int, three: Int, four: Int)
        }

        let enumCase: EnumCase = .caseOne(
            one: 0,
            two: 0,
            three: 0,
            four: 0
        )

        switch enumCase {
        case .caseOne(one: 1, two: 2, three: 3, four: 4):
            break
        default:
            break
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        """
        enum EnumCase: Error {
            case caseOne(Int, Int, Int, Int)
        }

        func mayThrow() throws {}

        do {
            try mayThrow()
        } catch EnumCase.caseOne(1, 2, 3, 4) {
            // pattern — must be ignored
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        // MARK: - Nested call inside a pattern constructor must be ignored too
        """
        enum Outer { case foo(Inner) }
        enum Inner { case bar(Int, Int, Int) }
        func test(_ x: Outer) {
            if case .foo(.bar(1, 2, 3)) = x {}
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        // MARK: - First arg ending with `]` or `}` skips full expansion
        """
        foo([
            1,
            2
        ], b: 3)
        """.asExample(configuration: ["allows_single_line": false]),
    ])

    static let triggeringExamples: [Example] = #examples([
        // MARK: - Single-line: too many args

        "foo(param1: 1, param2: false, ↓param3: [])"
            .asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        "Enum.foo(param1: 1, param2: false, ↓param3: [])"
            .asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        "foo(1, 2, ↓3)".asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2, ↓3)".asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // allows_single_line=false: any 2+ single-line call violates at 2nd argument
        "foo(param1: 1, ↓param2: false)".asExample(configuration: ["allows_single_line": false]),
        "Enum.foo(param1: 1, ↓param2: false)".asExample(configuration: ["allows_single_line": false]),

        // MARK: - Multi-line: two args start on the same line
        """
        foo(
            a: 1, ↓b: 2,
            c: 3
        )
        """,
        """
        foo(
            a: 1,
            b: 2, ↓c: 3
        )
        """,
        """
        foo(
            a: 1,
            b: 2,
            c: 3, ↓d: 4,
            e: 5
        )
        """,
        """
        foo(
            a: (
                1,
                2
            ), ↓b: 3
        )
        """.asExample(configuration: ["max_number_of_single_line_parameters": 1]
                     ),
        """
        foo(
            a: 1, /* comment */ ↓b: 2,
            c: 3
        )
        """,

        // MARK: - Multi-line: multiple duplicate argument start lines
        """
        foo(
            a: 1, ↓b: 2,
            c: 3, ↓d: 4
        )
        """,

        // MARK: - Enum-case constructor calls are linted like normal calls
        """
        enum EnumCase {
            case first(one: Int, two: Int, three: Int, four: Int)
        }
        EnumCase.first(one: 1, ↓two: 2, three: 3, four: 4)
        """.asExample(configuration: ["allows_single_line": false]),
        """
        enum EnumCase {
            case first(one: Int, two: Int, three: Int, four: Int)
        }
        let test = EnumCase.first(one: 1, two: 2, ↓three: 3, four: 4)
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // MARK: - Trailing closure: parentheses args still checked
        """
        foo(a: 1, ↓b: 2) { _ in
            print("x")
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 1]),

        // MARK: - Targeted tests

        // Targeted: real `.caseOne(1,2,3,4)` call MUST be linted (not a pattern)
        """
        enum EnumCase { case caseOne(Int, Int, Int, Int) }
        let x: EnumCase = .caseOne(1, 2, ↓3, 4)
        _ = x
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // Targeted: labeled enum-case constructor call MUST be linted
        """
        enum EnumCase {
            case caseOne(one: Int, two: Int, three: Int, four: Int)
        }
        let x: EnumCase = .caseOne(one: 1, two: 2, ↓three: 3, four: 4)
        _ = x
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // Targeted: pattern-part ignored, RHS call linted
        """
        func foo(a: Int, b: Int, c: Int) -> Int { a + b + c }
        enum EnumCase { case caseOne(Int, Int, Int, Int) }
        let enumCase: EnumCase = .caseOne(
            1,
            2,
            3,
            4
        )
        if case let .caseOne(_, _, _, _) = enumCase {
            _ = foo(a: 1, b: 2, ↓c: 3)
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // Targeted: switch-where RHS call linted, pattern ignored
        """
        func foo(a: Int, b: Int, c: Int) -> Bool { a + b == c }
        enum EnumCase { case caseOne(Int, Int, Int, Int) }
        let enumCase: EnumCase = .caseOne(
            1,
            2,
            3,
            4
        )
        switch enumCase {
        case .caseOne where foo(a: 1, b: 2, ↓c: 3):
            break
        default:
            break
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),

        // Targeted: for-case pattern ignored, body call linted
        """
        func foo(a: Int, b: Int, c: Int) -> Int { a + b + c }
        enum EnumCase { case caseOne(Int, Int, Int, Int) }
        let array: [EnumCase] = [
            .caseOne(
                1,
                2,
                3,
                4
            )
        ]
        for case let .caseOne(_, _, _, _) in array {
            _ = foo(a: 1, b: 2, ↓c: 3)
        }
        """.asExample(configuration: ["max_number_of_single_line_parameters": 2]),
        // MARK: - Tab indentation (uses global indentation setting)

        "foo(param1: 1, ↓param2: false)".asExample(configuration: ["allows_single_line": false]),
        """
        class Test {
            func method() {
                if condition {
                    foo(param1: 1, ↓param2: false)
                }
            }
        }
        """.asExample(configuration: ["allows_single_line": false]),
        // MARK: - Comments between arguments (violation still detected)

        "foo(param1: 1, /* comment */ ↓param2: false)".asExample(configuration: ["allows_single_line": false]),
        // MARK: - Nested single-line calls (both violate)

        "foo(bar(1, ↓2), ↓baz: 3)".asExample(configuration: ["allows_single_line": false]
                                            ),
        // MARK: - Nested multiline (closing `)` stranded with last arg)
        """
        foo(bar(
            a: 1,
            b: 2,
            c: 3
        ), ↓d: 4)
        """,
        // MARK: - Stranded `)` with first arg on its own line (closeParen branch, 2 args)
        """
        foo(
            a: bar(
                1
            ), ↓b: 2)
        """,
        // MARK: - Stranded `)` with 3+ args (no full expansion; converges over passes)
        """
        foo(a: bar(
            1
        ),
            b: 2, ↓c: 3)
        """,
    ])

    static let corrections: [Example: Example] = #corrections([
        // MARK: - Single-line corrections

        "foo(param1: 1, ↓param2: false)"
            .asExample(configuration: ["allows_single_line": false]):
        """
        foo(
            param1: 1,
            param2: false
        )
        """,

        "foo(param1: 1, param2: false, ↓param3: [])"
            .asExample(configuration: ["max_number_of_single_line_parameters": 2]):
        """
        foo(
            param1: 1,
            param2: false,
            param3: []
        )
        """,

        "foo(1, ↓2)".asExample(configuration: ["allows_single_line": false]):
        """
        foo(
            1,
            2
        )
        """,

        "foo(1, b: 2, ↓3)".asExample(configuration: ["max_number_of_single_line_parameters": 2])
        : """
            foo(
                1,
                b: 2,
                3
            )
            """,
        // MARK: - Multi-line: duplicate argument start line
        """
        foo(
            a: 1, ↓b: 2,
            c: 3
        )
        """: """
        foo(
            a: 1,
            b: 2,
            c: 3
        )
        """,
        // MARK: - Multi-line: four args, two on same line
        """
        foo(
            a: 1, ↓b: 2,
            c: 3,
            d: 4
        )
        """: """
        foo(
            a: 1,
            b: 2,
            c: 3,
            d: 4
        )
        """,
        // MARK: - Multi-line: multiple duplicate argument start lines
        """
        foo(
            a: 1, ↓b: 2,
            c: 3, ↓d: 4
        )
        """: """
        foo(
            a: 1,
            b: 2,
            c: 3,
            d: 4
        )
        """,
        // MARK: - Multi-line: newline after comma
        """
        foo(
            a: 1,
            b: 2, ↓c: 3
        )
        """: """
        foo(
            a: 1,
            b: 2,
            c: 3
        )
        """,
        // MARK: - Call with trailing closure

        "foo(a: 1, ↓b: 2) { _ in }".asExample(configuration: ["allows_single_line": false])
        : """
            foo(
                a: 1,
                b: 2
            ) { _ in }
            """,
        // MARK: - Closure as argument

        "foo(a: 1, ↓b: { x in x })".asExample(configuration: ["allows_single_line": false]):
        """
        foo(
            a: 1,
            b: { x in x }
        )
        """,
        // MARK: - Enum case call

        "Enum.foo(param1: 1, ↓param2: false)".asExample(configuration: ["allows_single_line": false])
        : """
            Enum.foo(
                param1: 1,
                param2: false
            )
            """,
        // MARK: - Tuple argument (stays on same line)

        "foo(a: (1, 2), ↓b: 3)".asExample(configuration: ["max_number_of_single_line_parameters": 1])
        : """
            foo(
                a: (1, 2),
                b: 3
            )
            """,
        // MARK: - Enum-case constructor call

        "EnumCase.first(one: 1, ↓two: 2)".asExample(configuration: ["allows_single_line": false])
        : """
            EnumCase.first(
                one: 1,
                two: 2
            )
            """,
        // MARK: - Multi-line with tuple argument
        """
        foo(
            a: (1, 2), ↓b: 3
        )
        """.asExample(configuration: ["max_number_of_single_line_parameters": 1]): """
        foo(
            a: (1, 2),
            b: 3
        )
        """,
        // MARK: - Nested indentation (4 spaces default)
        """
        class Test {
            func method() {
                if condition {
                    foo(param1: 1, ↓param2: false)
                }
            }
        }
        """.asExample(configuration: ["allows_single_line": false]):
        """
        class Test {
            func method() {
                if condition {
                    foo(
                        param1: 1,
                        param2: false
                    )
                }
            }
        }
        """,
        // MARK: - Nested calls (inner call already correct, outer has violation)
        "foo(bar(1), ↓baz: 3)".asExample(configuration: ["allows_single_line": false])
        : """
            foo(
                bar(1),
                baz: 3
            )
            """,
        // MARK: - Nested multiline (inner call already multiline, outer duplicate start line)
        """
        foo(
            bar(
                1,
                2
            ), ↓baz: 3
        )
        """: """
        foo(
            bar(
                1,
                2
            ),
            baz: 3
        )
        """,
        // MARK: - Nested multiline (closing `)` stranded with last argument)
        """
        foo(bar(
            a: 1,
            b: 2,
            c: 3
        ), ↓d: 4)
        """: """
        foo(
            bar(
                a: 1,
                b: 2,
                c: 3
            ),
            d: 4
        )
        """,
        // MARK: - Stranded `)` with first arg on its own line (closeParen branch)
        """
        foo(
            a: bar(
                1
            ), ↓b: 2)
        """: """
        foo(
            a: bar(
                1
            ),
            b: 2
        )
        """,
        // MARK: - Nested single-line calls (inner correction suppressed)
        "foo(bar(1, ↓2), ↓baz: 3)".asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
            foo(
                bar(1, 2),
                baz: 3
            )
            """,
        "grandFoo(singleArgFoo(bar(1, ↓2)), ↓baz: 3)"
            .asExample(
                configuration: ["allows_single_line": false],
                excludeFromDocumentation: true
            ): """
        grandFoo(
            singleArgFoo(bar(1, 2)),
            baz: 3
        )
        """,
        "foo(bar(1, ↓2, ↓3), ↓baz: 4, ↓qux: 5)".asExample(
            configuration: ["max_number_of_single_line_parameters": 2],
            excludeFromDocumentation: true
        ): """
            foo(
                bar(1, 2, 3),
                baz: 4,
                qux: 5
            )
            """,
        // MARK: - Nested with comments (inner correction allowed)
        "foo(bar(1, ↓2) /* c */, ↓baz: 3)".asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
            foo(bar(
                1,
                2
            ) /* c */, baz: 3)
            """,
        // MARK: - Open paren on new line
        """
        foo(
            a: 1, ↓b: 2)
        """.asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
        foo(
            a: 1,
            b: 2
        )
        """,
        // MARK: - Multi-line closure argument reindentation
        """
        foo(a: 1, ↓b: {
            x
        })
        """.asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
        foo(
            a: 1,
            b: {
                x
            }
        )
        """,
        // MARK: - Deeply nested calls (inner correction suppressed)
        "outer(middle(inner(1, 2), 3), ↓4)".asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
            outer(
                middle(inner(1, 2), 3),
                4
            )
            """,
        "outer(single(middle(1, 2)), ↓3)".asExample(
            configuration: ["allows_single_line": false],
            excludeFromDocumentation: true
        ): """
            outer(
                single(middle(1, 2)),
                3
            )
            """,
        "outer(middle(1, 2, 3), 4, ↓5)".asExample(
            configuration: ["max_number_of_single_line_parameters": 2],
            excludeFromDocumentation: true
        ): """
            outer(
                middle(1, 2, 3),
                4,
                5
            )
            """,
        // MARK: - Full expansion variants
        """
        foo(bar(
            a: 1,
            b: 2
        ), ↓c: 3)
        """.asExample(excludeFromDocumentation: true): """
        foo(
            bar(
                a: 1,
                b: 2
            ),
            c: 3
        )
        """,
        """
        foo(bar(
            1,
            2
        ), ↓3)
        """.asExample(excludeFromDocumentation: true): """
        foo(
            bar(
                1,
                2
            ),
            3
        )
        """,
        """
        foo(a: bar(
            1
        ), ↓b: 2)
        """.asExample(excludeFromDocumentation: true): """
        foo(
            a: bar(
                1
            ),
            b: 2
        )
        """,
        // MARK: - CloseParen variants (unlabeled, 3+ args)
        """
        foo(
            bar(
                1
            ), ↓2)
        """.asExample(excludeFromDocumentation: true): """
        foo(
            bar(
                1
            ),
            2
        )
        """,
        """
        foo(
            a: 1,
            b: bar(
                2
            ), ↓c: 3)
        """.asExample(excludeFromDocumentation: true): """
        foo(
            a: 1,
            b: bar(
                2
            ),
            c: 3
        )
        """,
        // MARK: - 3+ arguments: multiple corrections in one pass
        """
        foo(a: bar(
            1
        ), b: 2, ↓c: 3)
        """.asExample(excludeFromDocumentation: true): """
        foo(a: bar(
            1
        ),
            b: 2,
            c: 3)
        """,
    ])
}
