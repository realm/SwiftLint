import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

// swiftlint:disable file_length

private let detectingTypes = ["actor", "class", "struct", "enum"]

@Suite(.rulesRegistered)
struct NestingRuleTests { // swiftlint:disable:this type_body_length
    @Test
    func nestingWithAlwaysAllowOneTypeInFunctions() { // swiftlint:disable:this function_body_length
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
                    \(type) Example_0 {
                        \(type) Example_1 {
                            func f_0() {
                                \(type) Example_2 {}
                            }
                        }
                    }
                """,

                """
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
                """,

                """
                    func f_0() {
                        \(type) Example_0 {
                            \(type) Example_1 {}
                        }
                    }
                """,
            ])
        })
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
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
                """,

                """
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
                """,
            ])
        })

        var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
                    \(type) Example_0 {
                       \(type) Example_1 {
                           func f_0() {
                               \(type) Example_2 {
                                   ↓\(type) Example_3 {}
                               }
                           }
                       }
                    }
                """,

                """
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
                """,

                """
                    func f_0() {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               ↓\(type) Example_2 {}
                           }
                       }
                    }
                """,
            ])
        }

        // swiftlint:disable:next closure_body_length
        triggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
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
                """,

                """
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
                """,
            ])
        })

        let description = RuleDescription(
            identifier: NestingRule.identifier,
            name: NestingRule.description.name,
            description: NestingRule.description.description,
            kind: .metrics,
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples
        )

        verifyRule(description, ruleConfiguration: ["always_allow_one_type_in_functions": true])
    }

    @Test
    func nestingWithoutCheckNestingInClosuresAndStatements() { // swiftlint:disable:this function_body_length
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        // swiftlint:disable:next closure_body_length
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
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
                """,

                """
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
                """,

                """
                    for i in indicies {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """,

                """
                    while true {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """,

                """
                    repeat {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    } while true
                """,

                """
                    if flag {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """,

                """
                    guard flag else {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                       return
                    }
                """,

                """
                    defer {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """,

                """
                    do {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    } catch {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               \(type) Example 2 {}
                           }
                       }
                       func f_0() {
                           func f_1() {
                               func f_2() {
                                   func f_3() {}
                               }
                           }
                       }
                    }
                """,
            ])
        })

        // swiftlint:disable:next closure_body_length
        var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
                    \(type) Example_0 {
                        \(type) Example_1 {
                            ↓\(type) Example_2 {}
                        }
                    }
                """,

                """
                    var example: Int {
                       \(type) Example_0 {
                           \(type) Example_1 {
                               ↓\(type) Example_2 {}
                           }
                       }
                       return 5
                    }
                """,

                """
                    var example: Int = 5 {
                       didSet {
                           \(type) Example_0 {
                               \(type) Example_1 {
                                   ↓\(type) Example_2 {}
                               }
                           }
                       }
                    }
                """,

                """
                    extension Example_0 {
                       \(type) Example_1 {
                           ↓\(type) Example_2 {}
                       }
                    }
                """,

                """
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
                """,
            ])
        }

        triggeringExamples.append(contentsOf: #examples([
            """
                func f_0() {
                   func f_1() {
                       func f_2() {
                           ↓func f_3() {}
                       }
                   }
                }
            """,

            """
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
            """,

            """
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
            """,

            """
                extension Example_0 {
                   func f_0() {
                       func f_1() {
                           func f_2() {
                               ↓func f_3() {}
                           }
                       }
                   }
                }
            """,
        ]))

        let description = RuleDescription(
            identifier: NestingRule.identifier,
            name: NestingRule.description.name,
            description: NestingRule.description.description,
            kind: .metrics,
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples
        )

        verifyRule(description, ruleConfiguration: ["check_nesting_in_closures_and_statements": false])
    }

    @Test
    func nestingWithoutTypealiasAndAssociatedtype() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            #examples([
                """
                    \(type) Example_0 {
                        \(type) Example_1 {
                            typealias Example_2_Type = Example_2.Type
                        }
                        \(type) Example_2 {}
                    }
                """,
                """
                    protocol Example_Protcol {
                        associatedtype AssociatedType
                    }

                    \(type) Example_1 {
                        \(type) Example_2: Example_Protcol {
                            typealias AssociatedType = Int
                        }
                    }
                """,
                """
                    protocol Example_Protcol {
                        associatedtype AssociatedType
                    }

                    \(type) Example_1 {
                        \(type) Example_2: SomeProtcol {
                            typealias Example_2_Type = Example_2.Type
                        }
                        \(type) Example_3: Example_Protcol {
                            typealias AssociatedType = Int
                        }
                    }
                """,
            ])
        })

        let description = NestingRule.description.with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignore_typealiases_and_associatedtypes": true])
    }
}
