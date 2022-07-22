import class Down.Text
typealias MarkdownText = Text

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
        /// Foo takes `a`, ```b``` and `c`. Details follow.
        /// - Parameter a: a param.
        /// - parameter b: b param.
        /// - Parameter c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Foo summary followed by details.
        ///
        /// Detailed discussion about foo awesome properties.
        /// - PARAMETERS:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        /// Foo summary followed by details.
        ///
        /// Detailed discussion about foo awesome properties.
        /// - Parameter a: a param.
        /// - parameter b: b param.
        /// - Parameter c: c param.
        /// - throws: something.
        /// - returns: nothing
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
        ↓/// Parameters section is out of order.
        /// - Parameters:
        ///   - a: a param.
        ///   - c: c param.
        ///   - b: b param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Separate parameter fields are out of order.
        /// - Parameter a: a param.
        /// - Parameter c: c param.
        /// - Parameter b: b param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Missing parameter.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Missing parameter.
        /// - Parameter a: a param.
        /// - Parameter b: b param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Extra parameter.
        /// - Parameters:
        ///   - a: a param.
        ///   - b: b param.
        ///   - c: c param.
        ///   - d: d param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// Extra parameter.
        /// - Parameter a: a param.
        /// - Parameter b: b param.
        /// - Parameter c: c param.
        /// - Parameter d: d param.
        func foo(a: Int, b: Bool, c: String) { }
        """),
        Example("""
        ↓/// No space after 'parameter'.
        /// - Parametera: a param.
        /// - parameterb: b param.
        /// - Parameterc: c param.
        func foo(a: Int, b: Bool, c: String) { }
        """)
    ]
}
