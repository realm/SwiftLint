// swiftlint:disable file_length
// swiftlint:disable:next type_body_length type_name
internal struct VerticalWhitespaceBetweenCasesRuleExamples {
    private static let noSeparation = ["separation": "never"]

    static let nonTriggeringExamples = #examples([
        """
            switch x {

            case 0..<5:
                print("x is low")

            case 5..<10:
                print("x is high")

            default:
                print("x is invalid")

            @unknown default:
                print("x is out of this world")
            }
            """,
        """
            switch x {
            case 0..<5:
                print("x is low")

            case 5..<10:
                print("x is high")

            default:
                print("x is invalid")
            }
            """,
        """
            switch x {
            case 0..<5: print("x is low")
            case 5..<10: print("x is high")
            default: print("x is invalid")
            @unknown default: print("x is out of this world")
            }
            """,
        // Testing handling of trailing spaces
        """
            switch x {    \("")
            case 1:    \("")
                print("one")    \("")
                \("")
            default:    \("")
                print("not one")    \("")
            }    \("")
            """,
        // Test with compiler directives (#if/#endif)
        """
            switch x {
            case .a: print("a")

            #if DEBUG
            case .b: print("b")
            #endif

            case .c: print("c")
            }
            """,
        // Test #if in the middle of cases
        """
            switch x {
            case .a:
                print("a")

            #if DEBUG
            case .b:
                print("b")
            #endif

            case .c:
                print("c")
            }
            """,
        // Comments between cases - empty line still required
        """
            switch x {
            case .a:
                print("a")

            // Comment about case b
            case .b:
                print("b")
            }
            """,
        """
            switch x {
            case .a:
                print("a")

            /* Block comment */
            case .b:
                print("b")
            }
            """,
        // Comment as part of case body (not a separator)
        """
            switch x {
            case .a:
                // Comment inside case a
                print("a")

            case .b:
                print("b")
            }
            """,
        // separation: never - no blank lines
        """
            switch x {
            case .a:
                print("a")
            case .b:
                print("b")
            case .c:
                print("c")
            }
            """.configuration(noSeparation),
        // separation: never - no blank lines with comments
        """
            switch x {
            case .a:
                print("a")
            // Comment
            case .b:
                print("b")
            }
            """.configuration(noSeparation),
        // separation: always (default) - one blank line with comments
        """
            switch x {
            case .a:
                print("a")

            /// Documentation
            case .b:
                print("b")
            }
            """,
        """
            switch x {
            case .gamma:
                print("gamma")


            case .delta:
                print("delta")
            }
            """,
    ])

    static let violatingToValidExamples: [Example: Example] = #corrections([
        """
            switch x {
            case 0..<5:
                return "x is valid"
            ↓default:
                return "x is invalid"
            ↓@unknown default:
                print("x is out of this world")
            }
            """: """
                switch x {
                case 0..<5:
                    return "x is valid"

                default:
                    return "x is invalid"

                @unknown default:
                    print("x is out of this world")
                }
                """,
        """
            switch x {
            case 0..<5:
                print("x is valid")
            ↓default:
                print("x is invalid")
            }
            """: """
                switch x {
                case 0..<5:
                    print("x is valid")

                default:
                    print("x is invalid")
                }
                """,
        """
            switch x {
            case .valid:
                print("x is valid")
            ↓case .invalid:
                print("x is invalid")
            }
            """: """
                switch x {
                case .valid:
                    print("x is valid")

                case .invalid:
                    print("x is invalid")
                }
                """,
        """
            switch x {
            case .valid:
                print("multiple ...")
                print("... lines")
            ↓case .invalid:
                print("multiple ...")
                print("... lines")
            }
            """: """
                switch x {
                case .valid:
                    print("multiple ...")
                    print("... lines")

                case .invalid:
                    print("multiple ...")
                    print("... lines")
                }
                """,
        // Violations should still be caught outside of #if blocks
        """
            switch x {
            case .a:
                print("a")
            ↓case .b:
                print("b")

            #if DEBUG
            case .c:
                print("c")
            #endif

            case .d:
                print("d")
            ↓case .e:
                print("e")
            }
            """: """
                switch x {
                case .a:
                    print("a")

                case .b:
                    print("b")

                #if DEBUG
                case .c:
                    print("c")
                #endif

                case .d:
                    print("d")

                case .e:
                    print("e")
                }
                """,
        // Violation after #endif
        """
            switch x {
            case .a:
                print("a")

            #if DEBUG
            case .b:
                print("b")
            #endif
            ↓case .c:
                print("c")
            }
            """: """
                switch x {
                case .a:
                    print("a")

                #if DEBUG
                case .b:
                    print("b")
                #endif

                case .c:
                    print("c")
                }
                """,
        // Block comment without blank line
        """
            switch x {
            case .a:
                print("a")
            /* Comment */
            ↓case .b:
                print("b")
            }
            """: """
                switch x {
                case .a:
                    print("a")

                /* Comment */
                case .b:
                    print("b")
                }
                """,
        // Doc comment without blank line
        """
            switch x {
            case .a:
                print("a")
            /// Documentation
            ↓case .b:
                print("b")
            }
            """: """
                switch x {
                case .a:
                    print("a")

                /// Documentation
                case .b:
                    print("b")
                }
                """,
        // Comment inside case body - blank line needed before next case
        """
            switch x {
            case .a:
                // Comment inside
                print("a")
            ↓case .b:
                print("b")
            }
            """: """
                switch x {
                case .a:
                    // Comment inside
                    print("a")

                case .b:
                    print("b")
                }
                """,
        // Line comment without blank line (checking correct indentation)
        """
                switch x {
                case .a:
                    print("a")
                    // Comment
                ↓case .b:
                    print("b")
                }
            """: """
                    switch x {
                    case .a:
                        print("a")
                        // Comment

                    case .b:
                        print("b")
                    }
                """,
        // Multiple comments without blank line (checking correct indentation)
        """
                switch x {
                case .a:
                    print("a")
                // Comment 1
                // Comment 2
                ↓case .b:
                    print("b")
                }
            """: """
                    switch x {
                    case .a:
                        print("a")

                    // Comment 1
                    // Comment 2
                    case .b:
                        print("b")
                    }
                """,
        """
                switch (i) {
                case 1: 1
                ↓#if canImport(FoundationNetworking)
                default: 2
                #else
                case 2:
                    2
                ↓case 3:
                    3
                #endif
                }
                """: """
                    switch (i) {
                    case 1: 1

                    #if canImport(FoundationNetworking)
                    default: 2
                    #else
                    case 2:
                        2

                    case 3:
                        3
                    #endif
                    }
                    """,
        // separation: never - remove blank lines
        """
            switch x {
            case .first:
                print("first")

            ↓case .second:
                print("second")
            }
            """.configuration(noSeparation): """
                switch x {
                case .first:
                    print("first")
                case .second:
                    print("second")
                }
                """.configuration(noSeparation),
        // separation: never - two blank lines should be reduced to zero
        """
            switch x {
            case .a:
                print("a")


            // Comment
            ↓case .b:
                print("b")
                // Another Comment


            ↓case .c:
                print("c")

            /*
             * Comment block
             */

            ↓↓case .d:
                print("d")
            }
            """.configuration(noSeparation): """
                switch x {
                case .a:
                    print("a")
                // Comment
                case .b:
                    print("b")
                    // Another Comment
                case .c:
                    print("c")
                /*
                 * Comment block
                 */
                case .d:
                    print("d")
                }
                """.configuration(noSeparation),
    ])
}
