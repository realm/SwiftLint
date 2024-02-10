// swiftlint:disable file_length
internal struct NestingRuleExamples {
    static let nonTriggeringExamples = nonTriggeringTypeExamples
        + nonTriggeringFunctionExamples
        + nonTriggeringClosureAndStatementExamples
        + nonTriggeringMixedExamples

    private static let nonTriggeringTypeExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // default maximum type nesting level
                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {}
                    }
                """),

                /*
                 all variableKinds of SwiftDeclarationKind (except .varParameter which is a function parameter)
                 are flattend in a file structure so limits do not change
                */
                .init("""
                    var example: Int {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                        return 5
                    }
                """),

                // didSet is not present in file structure although there is such a swift declaration kind
                .init("""
                    var example: Int = 5 {
                        didSet {
                            \(type) Example_0 {
                                \(type) Example_1 {}
                            }
                        }
                    }
                """),

                // extensions are counted as a type level
                .init("""
                    extension Example_0 {
                        \(type) Example_1 {}
                    }
                """)
            ]
        }

    private static let nonTriggeringFunctionExamples: [Example] = [
        // default maximum function nesting level
        .init("""
            func f_0() {
                func f_1() {
                    func f_2() {}
                }
            }
        """),

        /*
         all variableKinds of SwiftDeclarationKind (except .varParameter which is a function parameter)
         are flattend in a file structure so level limits do not change
        */
        .init("""
            var example: Int {
                func f_0() {
                    func f_1() {
                        func f_2() {}
                    }
                }
                return 5
            }
        """),

        // didSet is not present in file structure although there is such a swift declaration kind
        .init("""
            var example: Int = 5 {
                didSet {
                    func f_0() {
                        func f_1() {
                            func f_2() {}
                        }
                    }
                }
            }
        """),

        // extensions are counted as a type level
        .init("""
            extension Example_0 {
                func f_0() {
                    func f_1() {
                        func f_2() {}
                    }
                }
            }
        """)
    ]

    private static let nonTriggeringClosureAndStatementExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // swich statement example
                .init("""
                    switch example {
                    case .exampleCase:
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                    default:
                        func f_0() {
                            func f_1() {
                                func f_2() {}
                            }
                        }
                    }
                """),

                // closure var example
                .init("""
                    var exampleClosure: () -> Void = {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                        func f_0() {
                            func f_1() {
                                func f_2() {}
                            }
                        }
                    }
                """),

                // function closure parameter example
                .init("""
                    exampleFunc(closure: {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                        func f_0() {
                            func f_1() {
                                func f_2() {}
                            }
                        }
                    })
                """)
            ]
        }

    private static let nonTriggeringMixedExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // default maximum nesting level for both type and function (nesting order is arbitrary)
                .init("""
                    \(type) Example_0 {
                        func f_0() {
                            \(type) Example_1 {
                                func f_1() {
                                    func f_2() {}
                                }
                            }
                        }
                    }
                """),

                // default maximum nesting level for both type and function within closures and statements
                .init("""
                    \(type) Example_0 {
                        func f_0() {
                            switch example {
                            case .exampleCase:
                                \(type) Example_1 {
                                    func f_1() {
                                        func f_2() {}
                                    }
                                }
                            default:
                                exampleFunc(closure: {
                                    \(type) Example_1 {
                                        func f_1() {
                                            func f_2() {}
                                        }
                                    }
                                })
                            }
                        }
                    }
                """)
            ]
        }

    static let triggeringExamples = triggeringTypeExamples
        + triggeringFunctionExamples
        + triggeringClosureAndStatementExamples
        + triggeringMixedExamples

    private static let triggeringTypeExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // violation of default maximum type nesting level
                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {
                            ↓\(type) Example_2 {}
                        }
                    }
                """),

                /*
                 all variableKinds of SwiftDeclarationKind (except .varParameter which is a function parameter)
                 are flattend in a file structure so limits do not change
                 */
                .init("""
                    var example: Int {
                        \(type) Example_0 {
                            \(type) Example_1 {
                                ↓\(type) Example_2 {}
                            }
                        }
                        return 5
                    }
                """),

                // didSet is not present in file structure although there is such a swift declaration kind
                .init("""
                    var example: Int = 5 {
                        didSet {
                            \(type) Example_0 {
                                \(type) Example_1 {
                                    ↓\(type) Example_2 {}
                                }
                            }
                        }
                    }
                """),

                // extensions are counted as a type level, violation of default maximum type nesting level
                .init("""
                    extension Example_0 {
                        \(type) Example_1 {
                            ↓\(type) Example_2 {}
                        }
                    }
                """)
            ]
        }

    private static let triggeringFunctionExamples: [Example] = [
        // violation of default maximum function nesting level
        .init("""
            func f_0() {
                func f_1() {
                    func f_2() {
                        ↓func f_3() {}
                    }
                }
            }
        """),

        /*
         all variableKinds of SwiftDeclarationKind (except .varParameter which is a function parameter)
         are flattend in a file structure so level limits do not change
         */
        .init("""
            var example: Int {
                func f_0() {
                    func f_1() {
                        func f_2() {
                            ↓func f_3() {}
                        }
                    }
                }
                return 5
            }
        """),

        // didSet is not present in file structure although there is such a swift declaration kind
        .init("""
            var example: Int = 5 {
                didSet {
                    func f_0() {
                        func f_1() {
                            func f_2() {
                                ↓func f_3() {}
                            }
                        }
                    }
                }
            }
        """),

        // extensions are counted as a type level, violation of default maximum function nesting level
        .init("""
            extension Example_0 {
                func f_0() {
                    func f_1() {
                        func f_2() {
                            ↓func f_3() {}
                        }
                    }
                }
            }
        """)
    ]

    private static let triggeringClosureAndStatementExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // swich statement example
                .init("""
                    switch example {
                    case .exampleCase:
                        \(type) Example_0 {
                            \(type) Example_1 {
                                ↓\(type) Example_2 {}
                            }
                        }
                    default:
                        func f_0() {
                            func f_1() {
                                func f_2() {
                                    ↓func f_3() {}
                                }
                            }
                        }
                    }
                """),

                // closure var example
                .init("""
                    var exampleClosure: () -> Void = {
                        \(type) Example_0 {
                            \(type) Example_1 {
                                ↓\(type) Example_2 {}
                            }
                            }
                        func f_0() {
                            func f_1() {
                                func f_2() {
                                    ↓func f_3() {}
                                }
                            }
                        }
                    }
                """),

                // function closure parameter example
                .init("""
                    exampleFunc(closure: {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                        func f_0() {
                            func f_1() {
                                func f_2() {
                                    ↓func f_3() {}
                                }
                            }
                        }
                    })
                """)
            ]
        }

    private static let triggeringMixedExamples =
        ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                // violation of default maximum nesting level for both type and function (nesting order is arbitrary)
                .init("""
                    \(type) Example_0 {
                        func f_0() {
                            \(type) Example_1 {
                                func f_1() {
                                    func f_2() {
                                        ↓\(type) Example_2 {}
                                        ↓func f_3() {}
                                    }
                                }
                            }
                        }
                    }
                """),

                // violation of default maximum nesting level for both type and function within closures and statements
                .init("""
                    \(type) Example_0 {
                        func f_0() {
                            switch example {
                            case .exampleCase:
                                \(type) Example_1 {
                                    func f_1() {
                                        func f_2() {
                                            ↓\(type) Example_2 {}
                                            ↓func f_3() {}
                                        }
                                    }
                                }
                            default:
                                exampleFunc(closure: {
                                    \(type) Example_1 {
                                        func f_1() {
                                            func f_2() {
                                                ↓\(type) Example_2 {}
                                                ↓func f_3() {}
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                """)
            ]
        }
}
