@testable import SwiftLintFramework

class ExplicitTypeInterfaceRuleTests: SwiftLintTestCase {
    func testLocalVars() {
        let nonTriggeringExamples = [
            Example("func foo() {\nlet intVal: Int = 1\n}"),
            Example("""
            func foo() {
                bar {
                    let x: Int = 1
                }
            }
            """)
        ]
        let triggeringExamples = [
            Example("func foo() {\n↓let intVal = 1\n}"),
            Example("""
            func foo() {
                bar {
                    ↓let x = 1
                }
            }
            """)
        ]
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    func testExcludeLocalVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + [
            Example("func foo() {\nlet intVal = 1\n}")
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["local"]])
    }

    func testExcludeClassVars() {
        let nonTriggeringExamples = ExplicitTypeInterfaceRule.description.nonTriggeringExamples + [
            Example("class Foo {\n  static var myStaticVar = 0\n}\n"),
            Example("class Foo {\n  static let myStaticLet = 0\n}\n")
        ]
        let triggeringExamples: [Example] = [
            Example("class Foo {\n  ↓var myVar = 0\n\n}\n"),
            Example("class Foo {\n  ↓let mylet = 0\n\n}\n"),
            Example("class Foo {\n  ↓class var myClassVar = 0\n}\n")
        ]
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["excluded": ["static"]])
    }

    func testAllowRedundancy() {
        let nonTriggeringExamples: [Example] = [
            Example("class Foo {\n  var myVar: Int? = 0\n}\n"),
            Example("class Foo {\n  let myVar: Int? = 0\n}\n"),
            Example("class Foo {\n  static var myVar: Int? = 0\n}\n"),
            Example("class Foo {\n  class var myVar: Int? = 0\n}\n"),
            Example("class Foo {\n  static let shared = Foo()\n}\n"),
            Example("class Foo {\n  let myVar = Int(0)\n}\n"),
            Example("class Foo {\n  let myVar = Set<Int>(0)\n}\n"),
            Example("class Foo {\n  let regex = try! NSRegularExpression(pattern: \".*\")\n}\n"),
            Example("class Foo {\n  let regex = try? NSRegularExpression(pattern: \".*\")\n}\n"),
            Example("class Foo {\n  let array = [String]()\n}\n"),
            Example("class Foo {\n  let dict = [String: String]()\n}\n"),
            Example("class Foo {\n  let dict = [String: [String: Array<String>]]()\n}\n"),
            Example("class Foo {\n  let l10n = L10n.Communication.self\n}\n")
        ]
        let triggeringExamples: [Example] = [
            Example("class Foo {\n  ↓var myVar = 0\n\n}\n"),
            Example("class Foo {\n  ↓let mylet = 0\n\n}\n"),
            Example("class Foo {\n  ↓static var myStaticVar = 0\n}\n"),
            Example("class Foo {\n  ↓class var myClassVar = 0\n}\n"),
            Example("class Foo {\n  ↓let array = [\"foo\", \"bar\"]\n}\n"),
            Example("class Foo {\n  ↓let dict = [\"foo\": \"bar\"]\n}\n")
        ]
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["allow_redundancy": true])
    }

    func testEmbeddedInStatements() {
        let nonTriggeringExamples = [
            Example("""
            func foo() {
                var bar: String?
                guard let strongBar = bar else {
                    return
                }
            }
            """),
            Example("""
            struct SomeError: Error {}
            var error: Error?
            switch error {
            case let error as SomeError: break
            default: break
            }
            """)
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    func testCaptureGroup() {
        let nonTriggeringExamples = [
            Example("""
            var k: Int = 0
            _ = { [weak k] in
                print(k)
            }
            """),
            Example("""
            var k: Int = 0
            _ = { [unowned k] in
                print(k)
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    var k: Int = 0
                    _ = { [weak self, weak k] in
                        guard let strongSelf = self else { return }
                    }
                }
            }
            """)
        ]
        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }

    func testFastEnumerationDeclaration() {
        let nonTriggeringExaples = [
            Example("""
            func foo() {
                let elements: [Int] = [1, 2]
                for element in elements {}
            }
            """),
            Example("""
            func foo() {
                let elements: [Int] = [1, 2]
                for (index, element) in elements.enumerated() {}
            }
            """)
        ]

        let triggeringExamples = ExplicitTypeInterfaceRule.description.triggeringExamples
        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExaples)
        verifyRule(description)
    }

    func testSwitchCaseDeclarations() {
        let nonTriggeringExamples = [
            Example("""
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
            """),
            Example("""
            enum Foo {
                case failure(Any, Any)
            }
            func foo() {
                switch foo {
                case var (x, y): break
                }
            }
            """)
        ]

        let triggeringExamples = [
            Example("""
            enum Foo {
                case failure(Any)
                case success(Any)
            }
            func bar() {
                let foo: Foo = .success(1)
                switch foo {
                case .failure(let error): ↓let fooBar = 1
                case .success(let result): ↓let fooBar = 1
                }
            }
            """),
            Example("""
            enum Foo {
                case failure(Any, Any)
            }
            func foo() {
                let foo: Foo = .failure(1, 1)
                switch foo {
                case var .failure(x, y): ↓let fooBar = 1
                default: ↓let fooBar = 1
                }
            }
            """)
        ]

        let description = ExplicitTypeInterfaceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description)
    }
}
