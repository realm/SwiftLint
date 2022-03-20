internal struct StructuredFunctionDocRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
        /// Foo summary.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Foo summary followed by details.
        ///
        /// Detailed discussion about foo awesome properties.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Foo doc with no markdown, because only 2 parameters.
        func foo(a: Int, b: Bool) { }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        ↓/// Foo summary
        /// has too
        /// many lines.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Parameters aren't detailed.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Parameters are out of order.
        /// - Parameters:
        ///   - a: a param.
        ↓///   - c: c param.
        ///   - b: b param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Missing parameter.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.↓
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Extra parameter.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        ↓///   - d: d param.
        func foo(a: Int, b: Bool, c: String) { }
        """)
    ]
}
