@testable import SwiftLintBuiltInRules

class StatementPositionRuleTests: SwiftLintTestCase {
    let nonTriggeringExamples = [
        Example("if true {\n    foo()\n}\nelse {\n    bar()\n}"),
        Example("if true {\n    foo()\n}\nelse if true {\n    bar()\n}\nelse {\n    return\n}"),
        Example("if true { foo() }\nelse { bar() }"),
        Example("if true { foo() }\nelse if true { bar() }\nelse { return }"),
        Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
        Example("do {\n    foo()\n}\ncatch {\n    bar()\n}\ncatch {\n    return\n}"),
        Example("do { foo() }\ncatch { bar() }"),
        Example("do { foo() }\ncatch { bar() }\ncatch { return }")
    ]

    let triggeringExamples = [
        Example("if true {\n    foo()\n}↓ else {\n    bar()\n}"),
        Example("if true {\n    foo()\n}↓ else if true {\n    bar()\n}↓ else {\n    return\n}"),
        Example("if true {\n    foo()\n}↓\n    else {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓ catch {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓ catch let error {\n    bar()\n}↓ catch {\n    return\n}"),
        Example("do {\n    foo()\n}↓\n    catch {\n    bar()\n}")
    ]

    let corrections = [
        Example("if true {\n    foo()\n}↓\n    else {\n    bar()\n}"):
            Example("if true {\n    foo()\n}\nelse {\n    bar()\n}"),
        Example("if true {\n    foo()\n}↓ else if true {\n    bar()\n}↓ else {\n    bar()\n}"):
            Example("if true {\n    foo()\n}\nelse if true {\n    bar()\n}\nelse {\n    bar()\n}"),
        Example("  if true {\n    foo()\n  }↓\nelse if true {\n    bar()\n  }"):
            Example("  if true {\n    foo()\n  }\n  else if true {\n    bar()\n  }"),
        Example("do {\n    foo()\n}↓ catch {\n    bar()\n}"):
            Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
        Example("do {\n    foo()\n}↓\n    catch {\n    bar()\n}"):
            Example("do {\n    foo()\n}\ncatch {\n    bar()\n}"),
        Example("  do {\n    foo()\n  }↓\ncatch {\n    bar()\n  }"):
            Example("  do {\n    foo()\n  }\n  catch {\n    bar()\n  }")
    ]

    func testUncuddled() {
        let configuration = ["statement_mode": "uncuddled_else"]

        let description = StatementPositionRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: configuration)
    }
}
