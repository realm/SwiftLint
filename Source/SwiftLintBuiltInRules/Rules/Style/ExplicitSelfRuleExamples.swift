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
        """),
        Example("""
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(self.foo)}"
            }
        }
        """, testWrappingInString: false),
        Example("""
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(self.foo)}"#
            }
        }
        """, testWrappingInString: false),
        Example("""
        class LocalStringInterpolation {
            var bar: String

            init() {
                let a = "a"
                let b = "b"
                self.bar = "\\(a)\\(b)".uppercased()
            }
        }
        """, testWrappingInString: false),
        Example("""
        class StringConcatenation {
            var description: String {
                let number = 1
                return "\\(number)" + " count"
            }
        }
        """, testWrappingInString: false),
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
        """),
        Example("""
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(↓foo)}"
            }
        }
        """, testWrappingInString: false),
        Example("""
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(↓foo)}"#
            }
        }
        """, testWrappingInString: false),
    ]

    static let corrections = [
        Example("""
        struct A {
            func f1() -> Int { 1 }
            func f2() -> Int { 2 }
            func f3() -> Int {
                ↓f1() + ↓f2()
            }
        }
        """):
        Example("""
        struct A {
            func f1() -> Int { 1 }
            func f2() -> Int { 2 }
            func f3() -> Int {
                self.f1() + self.f2()
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
        """),
        Example("""
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(↓foo)}"
            }
        }
        """, testWrappingInString: false): Example("""
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(self.foo)}"
            }
        }
        """, testWrappingInString: false),
        Example("""
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(↓foo)}"#
            }
        }
        """, testWrappingInString: false): Example("""
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(self.foo)}"#
            }
        }
        """, testWrappingInString: false),
    ]
}
