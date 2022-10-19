internal struct QuickDiscouragedFocusedTestRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   describe("bar") { }
                   context("bar") {
                       it("bar") { }
                   }
                   it("bar") { }
                   itBehavesLike("bar")
               }
           }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fdescribe("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fcontext("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fit("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   ↓fit("bar") { }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   ↓fit("bar") { }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("bar") {
                       ↓fit("toto") { }
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fitBehavesLike("foo")
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpecSubclass {
           override func spec() {
               ↓fitBehavesLike("foo")
           }
        }
        """)
    ]
}
