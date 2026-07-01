import SwiftLintCore

internal struct QuickDiscouragedPendingTestRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
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
        """,
    ])

    static let triggeringExamples = #examples([
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xdescribe("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xcontext("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xit("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   ↓xit("bar") { }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   ↓xit("bar") { }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("bar") {
                       ↓xit("toto") { }
                   }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓pending("foo")
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓xitBehavesLike("foo")
           }
        }
        """,
        """
        class TotoTests: QuickSpecSubclass {
           override func spec() {
               ↓xitBehavesLike("foo")
           }
        }
        """,
    ])
}
