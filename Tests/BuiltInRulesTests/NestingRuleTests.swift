@testable import SwiftLintBuiltInRules
import TestHelpers

// swiftlint:disable file_length

private let detectingTypes = ["actor", "class", "struct", "enum"]

// swiftlint:disable:next type_body_length
final class NestingRuleTests: SwiftLintTestCase {
    // swiftlint:disable:next function_body_length
    func testNestingWithAlwaysAllowOneTypeInFunctions() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
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
                """),
            ]
        })
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
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
                """),
            ]
        })

        var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
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
                """),
            ]
        }

        // swiftlint:disable:next closure_body_length
        triggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
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
                """),
            ]
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

    // swiftlint:disable:next function_body_length
    func testNestingWithoutCheckNestingInClosuresAndStatements() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        // swiftlint:disable:next closure_body_length
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),

                .init("""
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
                """),
            ]
        })

        // swiftlint:disable:next closure_body_length
        var triggeringExamples = detectingTypes.flatMap { type -> [Example] in
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
                """),
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
            """),
        ])

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

    func testNestingWithoutTypealiasAndAssociatedtype() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: detectingTypes.flatMap { type -> [Example] in
            [
                .init("""
                    \(type) Example_0 {
                        \(type) Example_1 {
                            typealias Example_2_Type = Example_2.Type
                        }
                        \(type) Example_2 {}
                    }
                """),
                .init("""
                    protocol Example_Protcol {
                        associatedtype AssociatedType
                    }

                    \(type) Example_1 {
                        \(type) Example_2: Example_Protcol {
                            typealias AssociatedType = Int
                        }
                    }
                """),
                .init("""
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
                """),
            ]
        })

        let description = NestingRule.description.with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignore_typealiases_and_associatedtypes": true])
    }

    func testNestingWithoutCodingKeys() {
        var nonTriggeringExamples = NestingRule.description.nonTriggeringExamples
        nonTriggeringExamples.append(contentsOf: [
            .init("""
                struct Outer {
                    struct Inner {
                        enum CodingKeys: String, CodingKey {
                            case id
                        }
                    }
                }
                """
             ),
        ])

        var triggeringExamples = NestingRule.description.triggeringExamples
        triggeringExamples.append(contentsOf: [
            .init("""
                struct Outer {
                    struct Inner {
                        ↓enum Example: String, CodingKey {
                            case id
                        }
                    }
                }
            """),
            .init("""
                struct Outer {
                  enum CodingKeys: String, CodingKey {
                    case id
                    
                    ↓struct S {}
                  }
                }
            """)
        ])

        let description = NestingRule.description.with(nonTriggeringExamples: nonTriggeringExamples, triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["ignore_coding_keys": true ])
    }
}
