internal struct ImplicitSelfRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct A {
           func f1() {}
           func f2() {
               f1()
           }
        }
        """),
        Example("""
        struct A {
           func f1() {}
           func f2() {
               let f1 = self.f1()
           }
        }
        """),
        Example("""
        class A {
           var p1: Int?
           func f1() {
               p1 = 1
           }
        }
        """),
        Example("""
        class A {
           var p1: Int?
           func f1() {
              guard let p1 = p1 else { return }
              let p2 = p1
              self.p1 = p2
           }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1(p1: Int) {
                self.p1 = p1
            }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1(_ p1: Int) {
                defer { self.p1 = p1 }
            }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1(_ p1: Int) {
                if true {
                    self.p1 = p1
                }
            }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1(p1: ()->Void) {
                p1()
                self.p1 = 1
            }
        }
        """),
        Example("""
        struct A {
            let p1: Int
            func f1(closure: @escaping ()->Void) {
                closure()
            }
            func f2() {
                f1(closure: { _ = self.p1 })
            }
        }
        """),
        Example("""
        struct A {
            let p1: Int
            func f1(closure: @escaping (_ p1: Int)->Void) {
                closure()
            }
            func f2() {
                f1(closure: { p1 in self.p1 = p1 })
            }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1(p1: ()->Void) {
                p1()
                self.p1 = 1
            }
        }
        """),
        Example("""
        class A {
            var p1: Int
            init() {
                self.init(p1: 2)
            }
            init(p1: Int) {
                self.p1 = p1
            }
        }
        """),
        Example("""
        class A {
            var p1: Int = 0
            func f1(arg1: [String: Any]) {
                for (key, value) in arg1 {
                    switch (key, value) {
                    case ("p1", let p1 as Int):
                        self.p1 = p1
                    default:
                        p1 = 2
                    }
                }
            }
        }
        """),
        Example("""
        extension Array {
            let index = 1
            var second: Element {
                return self[index]
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        struct A {
           func f1() {}
           func f2() {
               ↓self.f1()
           }
        }
        """),
        Example("""
        class A {
           var p1: Int?
           func f1() {
               ↓self.p1 = 1
           }
        }
        """),
        Example("""
        class A {
           var p1: Int?
           func f1() {
               ↓self.p1 = 1
               let p1 = 2
               self.p1 = p1
           }
        }
        """),
        Example("""
        class A {
            var p1: Int?
            func f1() {
                ↓self.p1 = 1
            }
            func f2(p1: Int) {
                _ = p1
            }
        }
        """),
        Example("""
        struct A {
            var p1: Int?
            var p2: Int?
            var p3: Int?
            var p4: Int?
            public mutating func apply(configuration: Any) {
                guard let configuration = configuration as? [String: Any] else {
                    return
                }
                for (key, value) in configuration {
                    switch (key, value) {
                    case (\"p1\", let v as? Int):
                        ↓self.p1 = v
                    case (\"p2\", let v as? Int):
                        ↓self.p2 = v
                    case (\"p3\", let v as? Int):
                        ↓self.p3 = v
                    case (\"p4\", let v as? Int):
                        ↓self.p4 = v
                    default: break
                    }
                }
            }
        }
        """)
    ]
}
