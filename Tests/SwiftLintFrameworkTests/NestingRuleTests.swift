@testable import SwiftLintBuiltInRules
import SwiftLintFramework

class NestingRuleTests: SwiftLintTestCase {
    // swiftlint:disable:next function_body_length
    func testNestingWithAlwaysAllowOneTypeInFunctions() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {
                            func f_0() {
                                \(type) Example_2 {}
                            }
                        }
                    }
                """),

                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {
                            func f_0() {
                                \(type) Example_2 {
                                    func f_1() {
                                        \(type) Example_3 {}
                                    }
                                }
                            }
                        }
                    }
                """),

                .init("""
                    func f_0() {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                    }
                """)
            ]
        })
        nonTriggeringExamples.append(contentsOf: ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    exampleFunc(closure: {
                        \(type) Example_0 {
                            \(type) Example_1 {
                                func f_0() {
                                   \(type) Example_2 {}
                               }
                           }
                       }
                       func f_0() {
                           \(type) Example_0 {
                               func f_1() {
                                   \(type) Example_1 {
                                       func f_2() {
                                           \(type) Example_2 {}
                                       }
                                   }
                               }
                           }
                       }
                    })
                """),

                .init("""
                    switch example {
                    case .exampleCase:
                       \(type) Example_0 {
                           \(type) Example_1 {
                               func f_0() {
                                   \(type) Example_2 {}
                               }
                           }
                       }
                    default:
                       func f_0() {
                           \(type) Example_0 {
                               func f_1() {
                                   \(type) Example_1 {
                                       func f_2() {
                                           \(type) Example_2 {}
                                       }
                                   }
                               }
                           }
                       }
                    }
                """)
            ]
        })

        var triggeringExamples = ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {
                                   ↓\(type) Example_3 {}
                               }
                           }
                       }
                    }
                """),

                .init("""
                    \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {
                                   func f_1() {
                                       \(type) Example_3 {
                                           ↓\(type) Example_4 {}
                                       }
                                   }
                               }
                           }
                       }
                    }
                """),

                .init("""
                    func f_0() {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               ↓\(type) Example_2 {}
                           }
                       }
                    }
                """)
            ]
        }

        triggeringExamples.append(contentsOf: ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    exampleFunc(closure: {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               func f_0() {
                                   \(type) Example_2 {
                                       ↓\(type) Example_3 {}
                                   }
                               }
                           }
                       }
                       func f_0() {
                           \(type) Example_0 {
                               func f_1() {
                                   \(type) Example_1 {
                                       func f_2() {
                                           \(type) Example_2 {
                                               ↓\(type) Example_3 {}
                                           }
                                       }
                                   }
                               }
                           }
                       }
                    })
                """),

                .init("""
                    switch example {
                    case .exampleCase:
                       \(type) Example_0 {
                           \(type) Example_1 {
                               func f_0() {
                                   \(type) Example_2 {
                                       ↓\(type) Example_3 {}
                                   }
                               }
                           }
                       }
                    default:
                       func f_0() {
                           \(type) Example_0 {
                               func f_1() {
                                   \(type) Example_1 {
                                       func f_2() {
                                           \(type) Example_2 {
                                               ↓\(type) Example_3 {}
                                           }
                                       }
                                   }
                               }
                           }
                       }
                    }
                """)
            ]
        })

        let description = RuleDescription(
            identifier: NestingRule.description.identifier,
            name: NestingRule.description.name,
            description: NestingRule.description.description,
            kind: .metrics,
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples
        )

        verifyRule(description, ruleConfiguration: ["always_allow_one_type_in_functions": true])
    }

    // swiftlint:disable:next function_body_length
    func testNestingWithoutCheckNestingInClosuresAndStatements() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    exampleFunc(closure: {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example_2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    })
                """),

                .init("""
                    switch example {
                    case .exampleCase:
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                    default:
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """)
            ]
        })

        var triggeringExamples = ["class", "struct", "enum"].flatMap { type -> [Example] in
            [
                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {
                            ↓\(type) Example_2 {}
                        }
                    }
                """),

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

                .init("""
                    extension Example_0 {
                       \(type) Example_1 {
                           ↓\(type) Example_2 {}
                       }
                    }
                """),

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
                """)
            ]
        }

        triggeringExamples.append(contentsOf: [
            .init("""
                func f_0() {
                   func f_1() {
                       func f_2() {
                           ↓func f_3() {}
                       }
                   }
                }
            """),

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
        ])

        let description = RuleDescription(
            identifier: NestingRule.description.identifier,
            name: NestingRule.description.name,
            description: NestingRule.description.description,
            kind: .metrics,
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples
        )

        verifyRule(description, ruleConfiguration: ["check_nesting_in_closures_and_statements": false])
    }
}
