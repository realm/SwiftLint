import SwiftLintCore

// swiftlint:disable file_length
struct MultilineCallArgumentsRuleExamples {
    static let nonTriggeringExamples: [Example] = #examples([
        // MARK: - Baseline: multi-line OK
        """
            foo(param1: 1,
                param2: false,
                param3: [])
            """.configuration(["max_number_of_single_line_parameters": 1]),
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
            """.configuration(["allows_single_line": false]),

        // MARK: - Baseline: single-line OK
        "foo(param1: 1, param2: false)".configuration(["max_number_of_single_line_parameters": 2]),
        "Enum.foo(param1: 1, param2: false)".configuration(["max_number_of_single_line_parameters": 2]),

        // allows_single_line=false does NOT affect 0/1-arg calls
        "foo()".configuration(["allows_single_line": false]),
        "foo(param1: 1)".configuration(["allows_single_line": false]),
        "Enum.foo(param1: 1)".configuration(["allows_single_line": false]),

        // MARK: - Unlabeled / mixed arguments
        "foo(1, 2)".configuration(["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2)".configuration(["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2, c: 3)".configuration(["max_number_of_single_line_parameters": 3]),

        // MARK: - Enum-case constructor calls are normal calls (stable by declaring the enum)
        """
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            EnumCase.first(one: 1, two: 2, three: 3, four: 4)
            """.configuration(["allows_single_line": true]),
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
            """.configuration(["allows_single_line": false]),

        // MARK: - Trailing closures are ignored by this rule (args-only)
        // Single-line args still use max_number_of_single_line_parameters
        """
            foo(a: 1, b: 2) { value in
                print(value)
            }
            """.configuration(["max_number_of_single_line_parameters": 2]),
        // Multi-line args remain valid regardless of closure placement
        """
            foo(
                a: 1,
                b: 2
            ) { value in
                print(value)
            }
            """.configuration(["allows_single_line": false]),
        """
            foo(
                a: 1,
                b: 2
            )
            { value in
                print(value)
            }
            """.configuration(["allows_single_line": false]),
        // No-parens form: no arguments list -> never violates
        """
            foo { value in
                print(value)
            }
            """.configuration(["max_number_of_single_line_parameters": 1]),
        // Multiple trailing closures: still args-only
        """
            foo(a: 1, b: 2) { _ in
                print("main")
            } trailing: { _ in
                print("extra")
            }
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["allows_single_line": false]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),
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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),
    ])

    static let triggeringExamples: [Example] = #examples([
        // MARK: - Single-line: too many args
        "foo(param1: 1, param2: false, ↓param3: [])".configuration(["max_number_of_single_line_parameters": 2]),
        "Enum.foo(param1: 1, param2: false, ↓param3: [])".configuration(["max_number_of_single_line_parameters": 2]),
        "foo(1, 2, ↓3)".configuration(["max_number_of_single_line_parameters": 2]),
        "foo(1, b: 2, ↓3)".configuration(["max_number_of_single_line_parameters": 2]),

        // allows_single_line=false: any 2+ single-line call violates at 2nd argument
        "foo(param1: 1, ↓param2: false)".configuration(["allows_single_line": false]),
        "Enum.foo(param1: 1, ↓param2: false)".configuration(["allows_single_line": false]),

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
            """.configuration(["max_number_of_single_line_parameters": 1]),
        """
            foo(
                a: 1, /* comment */ ↓b: 2,
                c: 3
            )
            """,

        // MARK: - Enum-case constructor calls are linted like normal calls
        """
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            EnumCase.first(one: 1, ↓two: 2, three: 3, four: 4)
            """.configuration(["allows_single_line": false]),
        """
            enum EnumCase {
                case first(one: Int, two: Int, three: Int, four: Int)
            }
            let test = EnumCase.first(one: 1, two: 2, ↓three: 3, four: 4)
            """.configuration(["max_number_of_single_line_parameters": 2]),

        // MARK: - Trailing closure: parentheses args still checked
        """
            foo(a: 1, ↓b: 2) { _ in
                print("x")
            }
            """.configuration(["max_number_of_single_line_parameters": 1]),

        // MARK: - Targeted tests

        // Targeted: real `.caseOne(1,2,3,4)` call MUST be linted (not a pattern)
        """
            enum EnumCase { case caseOne(Int, Int, Int, Int) }
            let x: EnumCase = .caseOne(1, 2, ↓3, 4)
            _ = x
            """.configuration(["max_number_of_single_line_parameters": 2]),

        // Targeted: labeled enum-case constructor call MUST be linted
        """
            enum EnumCase {
                case caseOne(one: Int, two: Int, three: Int, four: Int)
            }
            let x: EnumCase = .caseOne(one: 1, two: 2, ↓three: 3, four: 4)
            _ = x
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),

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
            """.configuration(["max_number_of_single_line_parameters": 2]),
        """
            func foo(a: Int, b: Int, c: Int) -> Int { a + b + c }
            enum EnumCase: Error { case caseOne(Int, Int, Int, Int) }

            func mayThrow() throws {
            }

            do {
                try mayThrow()
            } catch let EnumCase.caseOne(_, _, _, _) {
                _ = foo(a: 1, b: 2, ↓c: 3)
            }
            """.configuration(["max_number_of_single_line_parameters": 2]),
    ])
}
// swiftlint:enable file_length
