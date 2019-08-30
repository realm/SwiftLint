import SwiftLintFramework
import XCTest

class NPathComplexityRuleTests: XCTestCase {
    // NPath complexity: 8
    private lazy var simpleIfExample: String = {
        return """
        func ifsInALine() {
            if true != false {
                print("true")
            }
            if false != true {
                print("false")
            }
            if 2 + 2 == 5 {
                print("maybe")
            }
        }

        """
    }()

    // NPath complexity: 4
    private lazy var simpleNestedIfExample: String = {
        return """
               func nestedIfs() {
                   if true != false {
                       print("true")
                       if false != true {
                           print("false")
                           if 2 + 2 == 5 {
                               print("maybe")
                           }
                       }
                   }
               }
               """
    }()

    // NPath complexity: 8
    private lazy var nestedIfExample: String = {
        return """
                func nestedIfs() {
                    if true != false {
                        print("true")
                        if false != true {
                            print("false")
                            if 2 + 2 == 5 {
                                print("maybe")
                            }
                        }
                    }
                    if Bool.random() {
                        print("random")
                    }
                }

               """
    }()

    // NPath complexity: 4
    private lazy var guardExample: String = {
        return """
               func guardFunction() {
                   guard true != false else {
                       return
                   }

                   guard false != true else {
                       return
                   }

                   guard 5 < 4 else {
                       return
                   }
               }
               """
    }()

    // NPath complexity: 3
    private lazy var guardIfExample: String = {
        return """
               func guardIfFunction() {
                   guard true != false else {
                       return
                   }
                   if false == true {
                       print("here")
                   }
               }
               """
    }()

    // NPath complexity: 4
    private lazy var ifGuardExample: String = {
        return """
               func ifGuardFunction() {
                   if false == true {
                       print("here")
                   }
                   guard true != false else {
                       return
                   }
               }
               """
    }()

    // NPath complexity: 4
    private lazy var guardWithInnerIf: String = {
        return """
               func guardWithInnerIfFunction() {
                   guard true != false else {
                       if false == true {
                           print("here")
                       }
                       return
                   }
                   if true {
                       print("there")
                   }
               }
               """
    }()

    // NPath complexity: 2
    private lazy var simpleCaseExample: String = {
        return """
               func simpleCaseFunction() {
                   switch true {
                   case false:
                       break
                   default:
                       break
                   }
               }
               """
    }()

    // NPath complexity: 3
    // fallthrough does not affect NPath complexity
    private lazy var caseExample: String = {
        return """
               func caseFunction() {
                   switch 3 {
                   case 0:
                       fallthrough
                   case 1:
                       break
                   default:
                       break
                   }
               }
               """
    }()

    // NPath complexity: 4
    private lazy var caseIfExample: String = {
        return """
                func caseIfFunction() {
                    switch true {
                    case false:
                        break
                    case true:
                        break
                    }
                    if true {}
                }

               """
    }()

    // NPath complexity: 3
    private lazy var caseNestedIfExample: String = {
        return """
                func caseNestedIfFunction() {
                    switch true {
                    case false:
                        if true {}
                        break
                    case true:
                        break
                    }
                }

               """
    }()

    private lazy var forExample: String = {
        return """
            func forFunction() {
                for _ in (0 ... 100) {
                }
            }
            """
    }()

    private func verify(that example: String, hasComplexity complexity: Int) {
        let baseDescription = NPathComplexityRule.description

        let nonTriggeringDescription = baseDescription.with(nonTriggeringExamples: [example])
            .with(triggeringExamples: [])

        verifyRule(nonTriggeringDescription, ruleConfiguration: ["warning": complexity],
                   commentDoesntViolate: true, stringDoesntViolate: true)

        let triggeringDescription = baseDescription.with(nonTriggeringExamples: [])
            .with(triggeringExamples: [example])

        verifyRule(triggeringDescription, ruleConfiguration: ["warning": complexity - 1],
                   commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testNPathComplexityRule() {
        verifyRule(NPathComplexityRule.description, commentDoesntViolate: true, stringDoesntViolate: true)
    }

    func testSimpleNPathComplexity() {
        verify(that: simpleIfExample, hasComplexity: 8)
    }

    func testSimpleNestedIfExample() {
        verify(that: simpleNestedIfExample, hasComplexity: 4)
    }

    func testMoreComplexIfExample() {
        verify(that: nestedIfExample, hasComplexity: 8)
    }

    func testGuardExample() {
        verify(that: guardExample, hasComplexity: 4)
    }

    func testIfGuardExample() {
        verify(that: ifGuardExample, hasComplexity: 4)
    }

    func testGuardIfExample() {
        verify(that: guardIfExample, hasComplexity: 3)
    }

    func testGuardWithInnerIfExample() {
        verify(that: guardWithInnerIf, hasComplexity: 4)
    }

    func testSimpleCaseExample() {
        verify(that: simpleCaseExample, hasComplexity: 2)
    }

    func testCaseExample() {
        verify(that: caseExample, hasComplexity: 3)
    }

    func testCaseIfExample() {
        verify(that: caseIfExample, hasComplexity: 4)
    }

    func testCaseNestedIfExample() {
        verify(that: caseNestedIfExample, hasComplexity: 3)
    }

    func testForExample() {
        verify(that: forExample, hasComplexity: 2)
    }
}
