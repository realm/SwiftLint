@testable import SwiftLintBuiltInRules

class StatementPositionRuleTests: SwiftLintTestCase {
    let nonTriggeringExamples = [
        Example("""
        if true {
            foo()
        }
        else {
            bar()
        }
        """),
        Example("""
        if true {
            foo()
        }
        else if true {
            bar()
        }
        else {
            return
        }
        """),
        Example("""
        if true { foo() }
        else { bar() }
        """),
        Example("""
        if true { foo() }
        else if true { bar() }
        else { return }
        """),
        Example("""
        do {
            foo()
        }
        catch {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        }
        catch {
            bar()
        }
        catch {
            return
        }
        """),
        Example("""
        do { foo() }
        catch { bar() }
        """),
        Example("""
        do { foo() }
        catch { bar() }
        catch { return }
        """)
    ]

    let triggeringExamples = [
        Example("""
        if true {
            foo()
        ↓} else {
            bar()
        }
        """),
        Example("""
        if true {
            foo()
        ↓} else if true {
            bar()
        ↓} else {
            return
        }
        """),
        Example("""
        if true {
            foo()
        ↓}
            else {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓} catch {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓} catch let error {
            bar()
        ↓} catch {
            return
        }
        """),
        Example("""
        do {
            foo()
        ↓}
            catch {
            bar()
        }
        """)
    ]

    let corrections = [
        Example("""
        if true {
            foo()
        ↓}
            else {
            bar()
        }
        """):
            Example("""
            if true {
                foo()
            }
            else {
                bar()
            }
            """),
        Example("""
        if true {
            foo()
        ↓} else if true {
            bar()
        ↓} else {
            bar()
        }
        """):
            Example("""
            if true {
                foo()
            }
            else if true {
                bar()
            }
            else {
                bar()
            }
            """),
        Example("""
        do {
            foo()
        ↓} catch {
            bar()
        }
        """):
            Example("""
            do {
                foo()
            }
            catch {
                bar()
            }
            """),
        Example("""
        do {
            foo()
        ↓}
            catch {
            bar()
        }
        """):
            Example("""
            do {
                foo()
            }
            catch {
                bar()
            }
            """)
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
