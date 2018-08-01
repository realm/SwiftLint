import SwiftLintFramework
import XCTest

class ExplicitTypeInterfaceRuleTests: XCTestCase {

    func testExplicitTypeInterface() {
        verifyRule(ExplicitTypeInterfaceRule.description)
    }

    func testExcludeLocalVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + [
            "func foo() {\nlet intVal = 1\n}"
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["local"]])
    }

    func testExcludeClassVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + [
            "class Foo {\n  static var myStaticVar = 0\n}\n",
            "class Foo {\n  static let myStaticLet = 0\n}\n"
        ]
        let triggeringExamples = [
            "class Foo {\n  ↓var myVar = 0\n\n}\n",
            "class Foo {\n  ↓let mylet = 0\n\n}\n",
            "class Foo {\n  ↓class var myClassVar = 0\n}\n"
        ]
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["static"]])
    }

    func testAllowRedundancy() {
        let nonTriggeringExamples = [
            "class Foo {\n  var myVar: Int? = 0\n}\n",
            "class Foo {\n  let myVar: Int? = 0\n}\n",
            "class Foo {\n  static var myVar: Int? = 0\n}\n",
            "class Foo {\n  class var myVar: Int? = 0\n}\n",
            "class Foo {\n  static let shared = Foo()\n}\n",
            "class Foo {\n  let myVar = Int(0)\n}\n",
            "class Foo {\n  let myVar = Set<Int>(0)\n}\n"
        ]
        let triggeringExamples = [
            "class Foo {\n  ↓var myVar = 0\n\n}\n",
            "class Foo {\n  ↓let mylet = 0\n\n}\n",
            "class Foo {\n  ↓static var myStaticVar = 0\n}\n",
            "class Foo {\n  ↓class var myClassVar = 0\n}\n"
        ]

        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["allow_redundancy": true])
    }

    func testEmbededInStatements() {
        let nonTriggeringExamples = [
            "var foo: String?\n guard let strongFoo = foo else { return }",
            "struct SomeError: Error {}\n"      +
            "var error: Error?\n"               +
            "switch error {\n"                  +
            "case let error as SomeError:\n"    +
            "   break\n"                        +
            "default:\n"                        +
            "   break\n"                        +
            "}"
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    func testCaptureGroup() {
        let nonTriggeringExamples = [
            "var k: Int = 0\n"                                      +
            "_ = { [weak k] in\n"                                   +
            "       print(k)\n"                                     +
            "   }",
            "var k: Int = 0\n"                                      +
            "_ = { [unowned k] in\n"                                +
            "       print(k)\n"                                     +
            "   }",
            "class Foo {\n"                                         +
            "   func bar() {\n"                                     +
            "       var k: Int = 0\n"                               +
            "       _ = { [weak self, weak k] in\n"                 +
            "       guard let strongSelf = self else { return }\n"  +
            "       }\n"                                            +
            "   }\n"    +
            "}"
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }
}
