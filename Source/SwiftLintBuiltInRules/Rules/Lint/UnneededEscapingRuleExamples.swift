import SwiftLintCore

struct UnneededEscapingRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        func outer(completion: @escaping () -> Void) { inner(completion: completion) }
        """),
        Example("""
        func outer(closure: @escaping @autoclosure () -> String) {
            inner(closure: closure())
        }
        """),
        Example("""
        func returning(_ work: @escaping () -> Void) -> () -> Void { return work }
        """),
        Example("""
        func implicitlyReturning(g: @escaping () -> Void) -> () -> Void { g }
        """),
        Example("""
        struct S {
            var closure: (() -> Void)?
            mutating func setClosure(_ newValue: @escaping () -> Void) {
                closure = newValue
            }
            mutating func setToSelf(_ newValue: @escaping () -> Void) {
                self.closure = newValue
            }
        }
        """),
        Example("""
        func closure(completion: @escaping () -> Void) {
            DispatchQueue.main.async { completion() }
        }
        """),
        Example("""
        func capture(completion: @escaping () -> Void) {
            let closure = { completion() }
            closure()
        }
        """),
        Example("""
        func reassignLocal(completion: @escaping () -> Void) -> () -> Void {
            var local = { print("initial") }
            local = completion
            return local
        }
        """),
        Example("""
        func global(completion: @escaping () -> Void) {
            Global.completion = completion
        }
        """),
        Example("""
        func chain(c: @escaping () -> Void) -> () -> Void {
            let c1 = c
            if condition {
                let c2 = c1
                return c2
            }
            let c3 = c1
            return c3
        }
        """),
        Example("""
        var arrayOfCompletions = [() -> Void]()
        func array(completion: @escaping () -> Void) {
            var completions = [() -> Void]()
            completions[0] = completion
            arrayOfCompletions = completions
        }
        """, excludeFromDocumentation: true),
        Example("""
        var arrayOfCompletions = [() -> Void]()
        func array(completion: @escaping () -> Void) {
            arrayOfCompletions[0] = completion
        }
        """, excludeFromDocumentation: true),
        Example("""
        var _testSuiteFailedCallback: (() -> Void)?
        public func _setTestSuiteFailedCallback(_ callback: @escaping () -> Void) {
            _testSuiteFailedCallback = callback
        }
        """, excludeFromDocumentation: true),
        Example("""
        func f(c: @escaping () -> Void) {
            var cs = [() -> Void]()
            cs[0] = c
        }
        """, excludeFromDocumentation: true),
        Example("""
        func f(c: @escaping () -> Void) {
            var cs = [c]
        }
        """, excludeFromDocumentation: true),
        Example("""
        func f(c: @escaping () -> Void) {
            var cs = [1: c]
        }
        """, excludeFromDocumentation: true),
        Example("""
        func f(c: @escaping () -> Void) {
            f(true ? c : { })
        }
        """),
    ]

    static let triggeringExamples = [
        Example("""
        func f(c: ↓@escaping () -> Int) {
            print(c())
        }
        """),
        Example("""
        func forEach(action: ↓@escaping (Int) -> Void) {
            for i in 0..<10 {
                action(i)
            }
        }
        """),
        Example("""
        func process(completion: ↓@escaping () -> Void) {
            completion()
        }
        """),
        Example("""
        func apply(_ transform: ↓@escaping (Int) -> Int) -> Int {
            return transform(5)
        }
        """),
        Example("""
        func optional(completion: (↓@escaping () -> Void)?) {
            completion?()
        }
        """),
        Example("""
        func multiple(first: ↓@escaping () -> Void, second: ↓@escaping () -> Void) {
            first()
            second()
        }
        """),
        Example("""
        subscript(transform: ↓@escaping (Int) -> String) -> String {
            transform(42)
        }
        """),
        Example("""
        func assignToLocal(completion: ↓@escaping () -> Void) {
            let local = completion
            local()
        }
        """),
        Example("""
        func reassignLocal(completion: ↓@escaping () -> Void) {
            var local = { print(\"initial\") }
            local = completion
            local()
        }
        """),
        Example("""
        func assignToLocal(completion: ↓@escaping () -> Void) {
            _ = completion
        }
        """),
    ]

    static let corrections = [
        Example("""
        func forEach(action: ↓@escaping (Int) -> Void) {
            for i in 0..<10 {
                action(i)
            }
        }
        """): Example("""
            func forEach(action: (Int) -> Void) {
                for i in 0..<10 {
                    action(i)
                }
            }
            """),
        Example("""
        func process(completion: ↓@escaping () -> Void) { completion() }
        """): Example("""
            func process(completion: () -> Void) { completion() }
            """),
        Example("""
        subscript(transform: ↓@escaping (Int) -> String) -> String { transform(42) }
        """): Example("""
            subscript(transform: (Int) -> String) -> String { transform(42) }
            """),
        Example("""
        func f(c: ↓@escaping() -> Void) { c() }
        """): Example("""
            func f(c: () -> Void) { c() }
            """),
    ]
}
