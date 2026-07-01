import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ExplicitTypeInterfaceRuleTests {
    @Test
    func localVars() {
        let nonTriggeringExamples = #examples([
            "func foo() {\nlet intVal: Int = 1\n}",
            """
            func foo() {
                bar {
                    let x: Int = 1
                }
            }
            """,
        ])
        let triggeringExamples = #examples([
            "func foo() {\nlet ↓intVal = 1\n}",
            """
            func foo() {
                bar {
                    let ↓x = 1
                }
            }
            """,
        ])
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    @Test
    func excludeLocalVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + #examples([
            "func foo() {\nlet intVal = 1\n}"
        ])
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["local"]])
    }

    @Test
    func excludeClassVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + #examples([
            "class Foo {\n  static var myStaticVar = 0\n}\n",
            "class Foo {\n  static let myStaticLet = 0\n}\n",
        ])
        let triggeringExamples = #examples([
            "class Foo {\n  var ↓myVar = 0\n\n}\n",
            "class Foo {\n  let ↓myLet = 0\n\n}\n",
            "class Foo {\n  class var ↓myClassVar = 0\n}\n",
        ])
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["static"]])
    }

    @Test
    func allowRedundancy() {
        let nonTriggeringExamples = #examples([
            "class Foo {\n  var myVar: Int? = 0\n}\n",
            "class Foo {\n  let myVar: Int? = 0\n}\n",
            "class Foo {\n  static var myVar: Int? = 0\n}\n",
            "class Foo {\n  class var myVar: Int? = 0\n}\n",
            "class Foo {\n  static let shared = Foo()\n}\n",
            "class Foo {\n  let myVar = Int(0)\n}\n",
            "class Foo {\n  let myVar = Set<Int>(0)\n}\n",
            "class Foo {\n  let regex = try! NSRegularExpression(pattern: \".*\")\n}\n",
            "class Foo {\n  let regex = try? NSRegularExpression(pattern: \".*\")\n}\n",
            "class Foo {\n  let array = [String]()\n}\n",
            "class Foo {\n  let dict = [String: String]()\n}\n",
            "class Foo {\n  let dict = [String: [String: Array<String>]]()\n}\n",
            "class Foo {\n  let l10n = L10n.Communication.self\n}\n",
        ])
        let triggeringExamples = #examples([
            "class Foo {\n  var ↓myVar = 0\n\n}\n",
            "class Foo {\n  let ↓myLet = 0\n\n}\n",
            "class Foo {\n  static var ↓myStaticVar = 0\n}\n",
            "class Foo {\n  class var ↓myClassVar = 0\n}\n",
            "class Foo {\n  let ↓array = [\"foo\", \"bar\"]\n}\n",
            "class Foo {\n  let ↓dict = [\"foo\": \"bar\"]\n}\n",
        ])
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["allow_redundancy": true])
    }

    @Test
    func embeddedInStatements() {
        let nonTriggeringExamples = #examples([
            """
            func foo() {
                var bar: String?
                guard let strongBar = bar else {
                    return
                }
            }
            """,
            """
            struct SomeError: Error {}
            var error: Error?
            switch error {
            case let error as SomeError: break
            default: break
            }
            """,
        ])
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    @Test
    func captureGroup() {
        let nonTriggeringExamples = #examples([
            """
            var k: Int = 0
            _ = { [weak k] in
                print(k)
            }
            """,
            """
            var k: Int = 0
            _ = { [unowned k] in
                print(k)
            }
            """,
            """
            class Foo {
                func bar() {
                    var k: Int = 0
                    _ = { [weak self, weak k] in
                        guard let strongSelf = self else { return }
                    }
                }
            }
            """,
        ])
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    @Test
    func fastEnumerationDeclaration() {
        let nonTriggeringExamples = #examples([
            """
            func foo() {
                let elements: [Int] = [1, 2]
                for element in elements {}
            }
            """,
            """
            func foo() {
                let elements: [Int] = [1, 2]
                for (index, element) in elements.enumerated() {}
            }
            """,
        ])

        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description)
    }

    @Test
    func switchCaseDeclarations() {
        let nonTriggeringExamples = #examples([
            """
            enum Foo {
                case failure(Any)
                case success(Any)
            }
            func bar() {
                let foo: Foo = .success(1)
                switch foo {
                case .failure(let error):
                    let bar: Int = 1
                case .success(let result):
                    let bar: Int = 2
                }
            }
            """,
            """
            enum Foo {
                case failure(Any, Any)
            }
            func foo() {
                switch foo {
                case var (x, y): break
                }
            }
            """,
        ])

        let triggeringExamples = #examples([
            """
            enum Foo {
                case failure(Any)
                case success(Any)
            }
            func bar() {
                let foo: Foo = .success(1)
                switch foo {
                case .failure(let error): let ↓fooBar = 1
                case .success(let result): let ↓fooBar = 1
                }
            }
            """,
            """
            enum Foo {
                case failure(Any, Any)
            }
            func foo() {
                let foo: Foo = .failure(1, 1)
                switch foo {
                case var .failure(x, y): let ↓fooBar = 1
                default: let ↓fooBar = 1
                }
            }
            """,
        ])

        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description)
    }
}
