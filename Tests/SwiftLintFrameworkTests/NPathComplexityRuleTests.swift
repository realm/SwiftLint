import SwiftLintFramework
import XCTest

class NPathComplexityRuleTests: XCTestCase {
    private lazy var simpleIfExample: String = {
        return """
               // NPath complexity: 8
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

    private lazy var simpleNestedIfExample: String = {
        return """
               // NPath complexity: 4
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

    private lazy var nestedIfExample: String = {
        return """
               // NPath complexity: 8
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

    private lazy var guardExample: String = {
        return """
               // NPath complexity: 4
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

    private lazy var guardIfExample: String = {
        return """
               // NPath complexity: 3
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

    private lazy var ifGuardExample: String = {
        return """
               // NPath complexity: 4
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

    private lazy var guardWithInnerIf: String = {
        return """
               // NPath complexity: 4
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

    private lazy var simpleCaseExample: String = {
        return """
               // NPath complexity: 2
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

    // fallthrough does not affect NPath complexity
    private lazy var caseExample: String = {
        return """
               // NPath complexity: 3
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

    private lazy var caseIfExample: String = {
        return """
               // NPath complexity: 4
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

    private lazy var caseNestedIfExample: String = {
        return """
               // NPath complexity: 3
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
               // NPath complexity: 2
               func forFunction() {
                   for _ in (0 ... 100) {
                   }
               }
               """
    }()

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

private extension XCTestCase {
    func verify(that example: String, hasComplexity complexity: Int) {
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
}
