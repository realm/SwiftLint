struct ExplicitSelfRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        struct A {
            func f1() {}
            func f2() {
                self.f1()
            }
        }
        """),
        Example("""
        struct A {
            let p1: Int
            func f1() {
                _ = self.p1
            }
        }
        """),
        Example("""
        @propertyWrapper
        struct Wrapper<Value> {
            let wrappedValue: Value
            var projectedValue: [Value] {
                [self.wrappedValue]
            }
        }
        struct A {
            @Wrapper var p1: Int
            func f1() {
                self.$p1
                self._p1
            }
        }
        func f1() {
            A(p1: 10).$p1
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        struct A {
            func f1() {}
            func f2() {
                ↓f1()
            }
        }
        """),
        Example("""
        struct A {
            let p1: Int
            func f1() {
                _ = ↓p1
            }
        }
        """),
        Example("""
        struct A {
            func f1(a b: Int) {}
            func f2() {
                ↓f1(a: 0)
            }
        }
        """),
        Example("""
        @propertyWrapper
        struct Wrapper<Value> {
            let wrappedValue: Value
            var projectedValue: [Value] {
                [self.wrappedValue]
            }
        }
        struct A {
            @Wrapper var p1: Int
            func f1() {
                ↓$p1
                ↓_p1
            }
        }
        func f1() {
            A(p1: 10).$p1
        }
        """)
    ]

    static let corrections = [
        Example("""
        struct A {
            func f1() {}
            func f2() {
                ↓f1()
            }
        }
        """):
        Example("""
        struct A {
            func f1() {}
            func f2() {
                self.f1()
            }
        }
        """),
        Example("""
        struct A {
            let p1: Int
            func f1() {
                _ = ↓p1
            }
        }
        """):
        Example("""
        struct A {
            let p1: Int
            func f1() {
                _ = self.p1
            }
        }
        """),
        Example("""
        struct A {
            func f1(a b: Int) {}
            func f2() {
                ↓f1(a: 0)
            }
        }
        """):
        Example("""
        struct A {
            func f1(a b: Int) {}
            func f2() {
                self.f1(a: 0)
            }
        }
        """),
        Example("""
        @propertyWrapper
        struct Wrapper<Value> {
            let wrappedValue: Value
            var projectedValue: [Value] {
                [self.wrappedValue]
            }
        }
        struct A {
            @Wrapper var p1: Int
            func f1() {
                ↓$p1
                ↓_p1
            }
        }
        func f1() {
            A(p1: 10).$p1
        }
        """): Example("""
        @propertyWrapper
        struct Wrapper<Value> {
            let wrappedValue: Value
            var projectedValue: [Value] {
                [self.wrappedValue]
            }
        }
        struct A {
            @Wrapper var p1: Int
            func f1() {
                self.$p1
                self._p1
            }
        }
        func f1() {
            A(p1: 10).$p1
        }
        """)
    ]
}
