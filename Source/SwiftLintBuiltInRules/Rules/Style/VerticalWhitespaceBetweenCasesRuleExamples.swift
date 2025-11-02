// swiftlint:disable file_length
// swiftlint:disable:next type_body_length type_name
internal struct VerticalWhitespaceBetweenCasesRuleExamples {
    private static let noSeparation = ["separation": "never"]

    static let nonTriggeringExamples = [
        Example("""
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
            """),
        Example("""
            switch x {
            case 0..<5:
                print("x is low")

            case 5..<10:
                print("x is high")

            default:
                print("x is invalid")
            }
            """),
        Example("""
            switch x {
            case 0..<5: print("x is low")
            case 5..<10: print("x is high")
            default: print("x is invalid")
            @unknown default: print("x is out of this world")
            }
            """),
        // Testing handling of trailing spaces
        Example("""
            switch x {    \("")
            case 1:    \("")
                print("one")    \("")
                \("")
            default:    \("")
                print("not one")    \("")
            }    \("")
            """),
        // Test with compiler directives (#if/#endif)
        Example("""
            switch x {
            case .a: print("a")

            #if DEBUG
            case .b: print("b")
            #endif

            case .c: print("c")
            }
            """),
        // Test #if in the middle of cases
        Example("""
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
            """),
        // Comments between cases - empty line still required
        Example("""
            switch x {
            case .a:
                print("a")

            // Comment about case b
            case .b:
                print("b")
            }
            """),
        Example("""
            switch x {
            case .a:
                print("a")

            /* Block comment */
            case .b:
                print("b")
            }
            """),
        // Comment as part of case body (not a separator)
        Example("""
            switch x {
            case .a:
                // Comment inside case a
                print("a")

            case .b:
                print("b")
            }
            """),
        // separation: never - no blank lines
        Example("""
            switch x {
            case .a:
                print("a")
            case .b:
                print("b")
            case .c:
                print("c")
            }
            """, configuration: noSeparation),
        // separation: never - no blank lines with comments
        Example("""
            switch x {
            case .a:
                print("a")
            // Comment
            case .b:
                print("b")
            }
            """, configuration: noSeparation),
        // separation: always (default) - one blank line with comments
        Example("""
            switch x {
            case .a:
                print("a")

            /// Documentation
            case .b:
                print("b")
            }
            """),
        Example("""
            switch x {
            case .gamma:
                print("gamma")


            case .delta:
                print("delta")
            }
            """),
    ]

    static let violatingToValidExamples: [Example: Example] = [
        Example("""
            switch x {
            case 0..<5:
                return "x is valid"
            ↓default:
                return "x is invalid"
            ↓@unknown default:
                print("x is out of this world")
            }
            """): Example("""
                switch x {
                case 0..<5:
                    return "x is valid"

                default:
                    return "x is invalid"

                @unknown default:
                    print("x is out of this world")
                }
                """),
        Example("""
            switch x {
            case 0..<5:
                print("x is valid")
            ↓default:
                print("x is invalid")
            }
            """): Example("""
                switch x {
                case 0..<5:
                    print("x is valid")

                default:
                    print("x is invalid")
                }
                """),
        Example("""
            switch x {
            case .valid:
                print("x is valid")
            ↓case .invalid:
                print("x is invalid")
            }
            """): Example("""
                switch x {
                case .valid:
                    print("x is valid")

                case .invalid:
                    print("x is invalid")
                }
                """),
        Example("""
            switch x {
            case .valid:
                print("multiple ...")
                print("... lines")
            ↓case .invalid:
                print("multiple ...")
                print("... lines")
            }
            """): Example("""
                switch x {
                case .valid:
                    print("multiple ...")
                    print("... lines")

                case .invalid:
                    print("multiple ...")
                    print("... lines")
                }
                """),
        // Violations should still be caught outside of #if blocks
        Example("""
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
            """): Example("""
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
                """),
        // Violation after #endif
        Example("""
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
            """): Example("""
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
                """),
        // Block comment without blank line
        Example("""
            switch x {
            case .a:
                print("a")
            /* Comment */
            ↓case .b:
                print("b")
            }
            """): Example("""
                switch x {
                case .a:
                    print("a")

                /* Comment */
                case .b:
                    print("b")
                }
                """),
        // Doc comment without blank line
        Example("""
            switch x {
            case .a:
                print("a")
            /// Documentation
            ↓case .b:
                print("b")
            }
            """): Example("""
                switch x {
                case .a:
                    print("a")

                /// Documentation
                case .b:
                    print("b")
                }
                """),
        // Comment inside case body - blank line needed before next case
        Example("""
            switch x {
            case .a:
                // Comment inside
                print("a")
            ↓case .b:
                print("b")
            }
            """): Example("""
                switch x {
                case .a:
                    // Comment inside
                    print("a")

                case .b:
                    print("b")
                }
                """),
        // Line comment without blank line (checking correct indentation)
        Example("""
                switch x {
                case .a:
                    print("a")
                    // Comment
                ↓case .b:
                    print("b")
                }
            """): Example("""
                    switch x {
                    case .a:
                        print("a")
                        // Comment

                    case .b:
                        print("b")
                    }
                """),
        // Multiple comments without blank line (checking correct indentation)
        Example("""
                switch x {
                case .a:
                    print("a")
                // Comment 1
                // Comment 2
                ↓case .b:
                    print("b")
                }
            """): Example("""
                    switch x {
                    case .a:
                        print("a")

                    // Comment 1
                    // Comment 2
                    case .b:
                        print("b")
                    }
                """),
        Example("""
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
                """): Example("""
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
                    """),
        // separation: never - remove blank lines
        Example("""
            switch x {
            case .first:
                print("first")

            ↓case .second:
                print("second")
            }
            """, configuration: noSeparation): Example("""
                switch x {
                case .first:
                    print("first")
                case .second:
                    print("second")
                }
                """, configuration: noSeparation),
        // separation: never - two blank lines should be reduced to zero
        Example("""
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
            """, configuration: noSeparation): Example("""
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
                """, configuration: noSeparation),
    ]
}
