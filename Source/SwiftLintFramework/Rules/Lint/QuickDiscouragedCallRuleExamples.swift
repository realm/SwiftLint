internal struct QuickDiscouragedCallRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   beforeEach {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   beforeEach {
                       let foo = Foo()
                       foo.toto()
                   }
                   afterEach {
                       let foo = Foo()
                       foo.toto()
                   }
                   describe("bar") {
                   }
                   context("bar") {
                   }
                   it("bar") {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   justBeforeEach {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   aroundEach {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                  itBehavesLike("bar")
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   it("does something") {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   afterEach { toto.append(foo) }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               xcontext("foo") {
                   afterEach { toto.append(foo) }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               xdescribe("foo") {
                   afterEach { toto.append(foo) }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   xit("does something") {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               fcontext("foo") {
                   afterEach { toto.append(foo) }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               fdescribe("foo") {
                   afterEach { toto.append(foo) }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   fit("does something") {
                       let foo = Foo()
                       foo.toto()
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               fitBehavesLike("foo")
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               xitBehavesLike("foo")
           }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        class TotoTests {
           override func spec() {
               describe("foo") {
                   let foo = Foo()
               }
           }
        }
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("foo") {
                       let foo = ↓Foo()
                   }
                   context("bar") {
                       let foo = ↓Foo()
                       ↓foo.bar()
                       it("does something") {
                           let foo = Foo()
                           foo.toto()
                       }
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   context("foo") {
                       context("foo") {
                           beforeEach {
                               let foo = Foo()
                               foo.toto()
                           }
                           it("bar") {
                           }
                           context("foo") {
                               let foo = ↓Foo()
                           }
                       }
                   }
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               sharedExamples("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               describe("foo") {
                   ↓foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               context("foo") {
                   ↓foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               sharedExamples("foo") {
                   ↓foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               xdescribe("foo") {
                   let foo = ↓Foo()
               }
               fdescribe("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpec {
           override func spec() {
               xcontext("foo") {
                   let foo = ↓Foo()
               }
               fcontext("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """),
        Example("""
        class TotoTests: QuickSpecSubclass {
           override func spec() {
               xcontext("foo") {
                   let foo = ↓Foo()
               }
               fcontext("foo") {
                   let foo = ↓Foo()
               }
           }
        }
        """)
    ]
}
