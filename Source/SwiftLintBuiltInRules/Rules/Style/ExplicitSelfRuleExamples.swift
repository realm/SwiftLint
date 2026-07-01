struct ExplicitSelfRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        struct A {
            func f1() {}
            func f2() {
                self.f1()
            }
        }
        """,
        """
        struct A {
            let p1: Int
            func f1() {
                _ = self.p1
            }
        }
        """,
        """
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
        """,
        """
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(self.foo)}"
            }
        }
        """.skipWrappingInStringTest(),
        """
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(self.foo)}"#
            }
        }
        """.skipWrappingInStringTest(),
        """
        class LocalStringInterpolation {
            var bar: String

            init() {
                let a = "a"
                let b = "b"
                self.bar = "\\(a)\\(b)".uppercased()
            }
        }
        """.skipWrappingInStringTest(),
        """
        class StringConcatenation {
            var description: String {
                let number = 1
                return "\\(number)" + " count"
            }
        }
        """.skipWrappingInStringTest(),
    ])

    static let triggeringExamples = #examples([
        """
        struct A {
            func f1() {}
            func f2() {
                ↓f1()
            }
        }
        """,
        """
        struct A {
            let p1: Int
            func f1() {
                _ = ↓p1
            }
        }
        """,
        """
        struct A {
            func f1(a b: Int) {}
            func f2() {
                ↓f1(a: 0)
            }
        }
        """,
        """
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
        """,
        """
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(↓foo)}"
            }
        }
        """.skipWrappingInStringTest(),
        """
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(↓foo)}"#
            }
        }
        """.skipWrappingInStringTest(),
    ])

    static let corrections = #examplesDictionary([
        """
        struct A {
            func f1() -> Int { 1 }
            func f2() -> Int { 2 }
            func f3() -> Int {
                ↓f1() + ↓f2()
            }
        }
        """:
        """
        struct A {
            func f1() -> Int { 1 }
            func f2() -> Int { 2 }
            func f3() -> Int {
                self.f1() + self.f2()
            }
        }
        """,
        """
        struct A {
            let p1: Int
            func f1() {
                _ = ↓p1
            }
        }
        """:
        """
        struct A {
            let p1: Int
            func f1() {
                _ = self.p1
            }
        }
        """,
        """
        struct A {
            func f1(a b: Int) {}
            func f2() {
                ↓f1(a: 0)
            }
        }
        """:
        """
        struct A {
            func f1(a b: Int) {}
            func f2() {
                self.f1(a: 0)
            }
        }
        """,
        """
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
        """: """
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
        """,
        """
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(↓foo)}"
            }
        }
        """.skipWrappingInStringTest(): """
        class StringInterpolation {
            let foo = "foo"

            var description: String {
                return "StringInterpolation{foo: \\(self.foo)}"
            }
        }
        """.skipWrappingInStringTest(),
        """
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(↓foo)}"#
            }
        }
        """.skipWrappingInStringTest(): """
        class StringInterpolationRawStringLiteral {
            let foo = "foo"

            var description: String {
                return #"StringInterpolation{foo: \\#(self.foo)}"#
            }
        }
        """.skipWrappingInStringTest(),
    ])
}
