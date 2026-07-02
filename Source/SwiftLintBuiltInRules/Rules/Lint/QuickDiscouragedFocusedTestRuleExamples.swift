import SwiftLintCore

internal struct QuickDiscouragedFocusedTestRuleExamples {
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
               ↓fdescribe("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fcontext("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fit("foo") { }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   ↓fit("bar") { }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   ↓fit("bar") { }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("bar") {
                       ↓fit("toto") { }
                   }
               }
           }
        }
        """,
        """
        class TotoTests: QuickSpec {
           override func spec() {
               ↓fitBehavesLike("foo")
           }
        }
        """,
        """
        class TotoTests: QuickSpecSubclass {
           override func spec() {
               ↓fitBehavesLike("foo")
           }
        }
        """,
    ])
}
