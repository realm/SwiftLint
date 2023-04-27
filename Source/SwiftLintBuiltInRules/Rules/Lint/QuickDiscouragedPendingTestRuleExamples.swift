internal struct QuickDiscouragedPendingTestRuleExamples {
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
               ↓xdescribe("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xcontext("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xit("foo") { }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   ↓xit("bar") { }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   ↓xit("bar") { }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("bar") {
                       ↓xit("toto") { }
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓pending("foo")
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xitBehavesLike("foo")
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpecSubclass {
           override func spec() {
               ↓xitBehavesLike("foo")
           }
        }
        """)
    ]
}
