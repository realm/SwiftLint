@testable import SwiftLintBuiltInRules

class OpeningBraceRuleTests: SwiftLintTestCase {
    // swiftlint:disable function_body_length
    func testWithAllowMultilineTrue() {
        // Test with `same_line` set to false

        let nonTriggeringExamples = [
            Example("func abc() {\n}"),
            Example("func abc(a: A\n\tb: B)\n{"),
            Example("[].map() { $0 }"),
            Example("[].map({ })"),
            Example("if let a = b { }"),
            Example("while a == b { }"),
            Example("guard let a = b else { }"),
            Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else\n{ }"),
            Example("struct Rule {}\n"),
            Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("""
            func f(rect: CGRect) {
               {
                  let centre = CGPoint(x: rect.midX, y: rect.midY)
                  print(centre)
               }()
            }
            """),
            Example("""
            // Get the current thread's TLS pointer. On first call for a given thread,
            // creates and initializes a new one.
            internal static func getPointer()
              -> UnsafeMutablePointer<_ThreadLocalStorage>
            {
              return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                to: _ThreadLocalStorage.self)
            }
            """)
        ]
        let triggeringExamples = [
            Example("func abc()↓{\n}"),
            Example("func abc()\n\t↓{ }"),
            Example("[].map()↓{ $0 }"),
            Example("[].map( ↓{ } )"),
            Example("if let a = b↓{ }"),
            Example("while a == b↓{ }"),
            Example("guard let a = b else↓{ }"),
            Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else↓{ }"),
            Example("struct Rule↓{}\n"),
            Example("struct Rule\n↓{\n}\n"),
            Example("struct Rule\n\n\t↓{\n}\n"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("""
            func run_Array_method1x(_ N: Int) {
              let existentialArray = array!
              for _ in 0 ..< N * 100 {
                for elt in existentialArray {
                  if !elt.doIt()  {
                    fatalError("expected true")
                  }
                }
              }
            }

            func run_Array_method2x(_ N: Int) {

            }
            """)
        ]

        let corrections = [
            Example("struct Rule↓{}\n"): Example("struct Rule {}\n"),
            Example("struct Rule\n↓{\n}\n"): Example("struct Rule {\n}\n"),
            Example("struct Rule\n\n\t↓{\n}\n"): Example("struct Rule {\n}\n"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}\n"):
                Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n"),
            Example("[].map()↓{ $0 }\n"): Example("[].map() { $0 }\n"),
            Example("[].map( ↓{ })\n"): Example("[].map({ })\n"),
            Example("if a == b↓{ }\n"): Example("if a == b { }\n"),
            Example("if\n\tlet a = b,\n\tlet c = d↓{ }\n"): Example("if\n\tlet a = b,\n\tlet c = d { }\n")
        ]

        let description = OpeningBraceRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["allow_multiline_func": true])
    }
}
