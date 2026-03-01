// swiftlint:disable file_length
// swiftlint:disable type_body_length
internal struct MultilineCallArgumentsRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        // MARK: - Baseline: multi-line OK
        Example("""
            foo(param1: 1,
                param2: false,
                param3: [])
            """,
                configuration: ["max_number_of_single_line_parameters": 1]
               ),
        Example("""
            foo(
                param1: 1,
                param2: 2,
                param3: 3
            )
            """,
                configuration: ["allows_single_line": false]
               ),

        // MARK: - Baseline: single-line OK
        Example(
            "foo(param1: 1, param2: false)",
            configuration: ["max_number_of_single_line_parameters": 2]
        ),
        Example(
            "Enum.foo(param1: 1, param2: false)",
            configuration: ["max_number_of_single_line_parameters": 2]
        ),

        // allows_single_line=false does NOT affect 0/1-arg calls
        Example("foo()", configuration: ["allows_single_line": false]),
        Example("foo(param1: 1)", configuration: ["allows_single_line": false]),
        Example("Enum.foo(param1: 1)", configuration: ["allows_single_line": false]),

        // MARK: - Unlabeled / mixed arguments
        Example("foo(1, 2)", configuration: ["max_number_of_single_line_parameters": 2]),
        Example("foo(1, b: 2)", configuration: ["max_number_of_single_line_parameters": 2]),
        Example("foo(1, b: 2, c: 3)", configuration: ["max_number_of_single_line_parameters": 3]),

        // MARK: - Enum-case constructor calls are normal calls (stable by declaring the enum)
        Example("""
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            EnumCase.first(one: 1, two: 2, three: 3, four: 4)
            """,
                configuration: ["allows_single_line": true]
               ),
        Example("""
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            let test = EnumCase.first(
                one: 1,
                two: 2,
                three: 3,
                four: 4
            )
            """,
                configuration: ["allows_single_line": false]
               ),

        // MARK: - Trailing closures are ignored by this rule (args-only)
        // Single-line args still use max_number_of_single_line_parameters
        Example("""
            foo(a: 1, b: 2) { value in
                print(value)
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        // Multi-line args remain valid regardless of closure placement
        Example("""
            foo(
                a: 1,
                b: 2
            ) { value in
                print(value)
            }
            """,
                configuration: ["allows_single_line": false]
               ),
        Example("""
            foo(
                a: 1,
                b: 2
            )
            { value in
                print(value)
            }
            """,
                configuration: ["allows_single_line": false]
               ),
        // No-parens form: no arguments list -> never violates
        Example("""
            foo { value in
                print(value)
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 1]
               ),
        // Multiple trailing closures: still args-only
        Example("""
            foo(a: 1, b: 2) { _ in
                print("main")
            } trailing: { _ in
                print("extra")
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // MARK: - Trivia / comments
        Example("""
            foo(
                a: 1,
                // comment
                b: 2,
                c: 3
            )
            """),

        Example("""
            foo(
                a: (
                    1,
                    2
                ), b: 3
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),
        Example("""
            foo(
                a: 1, // comment
                b: 2,
                c: 3
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),

        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // MARK: - Pattern matching MUST be ignored: catch patterns
        Example("""
            enum EnumCase: Error {
                case caseOne(Int, Int, Int, Int)
            }

            func mayThrow() throws {
            }

            do {
                try mayThrow()
            } catch let EnumCase.caseOne(_, _, three, _) {
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
            enum EnumCase: Error {
                case caseOne(one: Int, two: Int, three: Int, four: Int)
            }

            func mayThrow() throws {
            }

            do {
                try mayThrow()
            } catch let EnumCase.caseOne(one: _, two: _, three: three, four: _) {
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // MARK: - Regular calls near patterns are still linted
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        // MARK: - Pattern matching MUST be ignored: enum-case patterns with literal subpatterns
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        Example("""
            enum EnumCase: Error {
                case caseOne(Int, Int, Int, Int)
            }

            func mayThrow() throws {}

            do {
                try mayThrow()
            } catch EnumCase.caseOne(1, 2, 3, 4) {
                // pattern — must be ignored
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
    ]

    static let triggeringExamples: [Example] = [
        // MARK: - Single-line: too many args
        Example(
            "foo(param1: 1, param2: false, ↓param3: [])",
            configuration: ["max_number_of_single_line_parameters": 2]
        ),
        Example(
            "Enum.foo(param1: 1, param2: false, ↓param3: [])",
            configuration: ["max_number_of_single_line_parameters": 2]
        ),
        Example("foo(1, 2, ↓3)", configuration: ["max_number_of_single_line_parameters": 2]),
        Example("foo(1, b: 2, ↓3)", configuration: ["max_number_of_single_line_parameters": 2]),

        // allows_single_line=false: any 2+ single-line call violates at 2nd argument
        Example("foo(param1: 1, ↓param2: false)", configuration: ["allows_single_line": false]),
        Example("Enum.foo(param1: 1, ↓param2: false)", configuration: ["allows_single_line": false]),

        // MARK: - Multi-line: two args start on the same line
        Example("""
            foo(
                a: 1, ↓b: 2,
                c: 3
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),
        Example("""
            foo(
                a: 1,
                b: 2, ↓c: 3
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),
        Example("""
            foo(
                a: 1,
                b: 2,
                c: 3, ↓d: 4,
                e: 5
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),
        Example("""
            foo(
                a: 1, /* comment */ ↓b: 2,
                c: 3
            )
            """,
                configuration: ["max_number_of_single_line_parameters": 10]
               ),

        // MARK: - Enum-case constructor calls are linted like normal calls
        Example("""
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            EnumCase.first(one: 1, ↓two: 2, three: 3, four: 4)
            """,
                configuration: ["allows_single_line": false]
               ),
        Example("""
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            let test = EnumCase.first(one: 1, two: 2, ↓three: 3, four: 4)
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // MARK: - Trailing closure: parentheses args still checked
        Example("""
            foo(a: 1, ↓b: 2) { _ in
                print("x")
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 1]
               ),

        // MARK: - Targeted tests

        // Targeted: real `.caseOne(1,2,3,4)` call MUST be linted (not a pattern)
        Example("""
            enum EnumCase { case caseOne(Int, Int, Int, Int) }
            let x: EnumCase = .caseOne(1, 2, ↓3, 4)
            _ = x
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // Targeted: labeled enum-case constructor call MUST be linted
        Example("""
            enum EnumCase {
                case caseOne(one: Int, two: Int, three: Int, four: Int)
            }
            let x: EnumCase = .caseOne(one: 1, two: 2, ↓three: 3, four: 4)
            _ = x
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // Targeted: pattern-part ignored, RHS call linted
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // Targeted: switch-where RHS call linted, pattern ignored
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),

        // Targeted: for-case pattern ignored, body call linted
        Example("""
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
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
        Example("""
            func foo(a: Int, b: Int, c: Int) -> Int { a + b + c }
            enum EnumCase: Error { case caseOne(Int, Int, Int, Int) }

            func mayThrow() throws {
            }

            do {
                try mayThrow()
            } catch let EnumCase.caseOne(_, _, _, _) {
                _ = foo(a: 1, b: 2, ↓c: 3)
            }
            """,
                configuration: ["max_number_of_single_line_parameters": 2]
               ),
    ]
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
