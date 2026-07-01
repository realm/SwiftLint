internal struct ClosureBodyLengthRuleExamples {
    static let nonTriggeringExamples = #examples([
        singleLineClosure(),
        trailingClosure(codeLinesCount: 0, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure(codeLinesCount: 1, commentLinesCount: 15, emptyLinesCount: 15),
        trailingClosure(codeLinesCount: 29, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure(codeLinesCount: 29, commentLinesCount: 15, emptyLinesCount: 15),
        argumentClosure(codeLinesCount: 0),
        argumentClosure(codeLinesCount: 1),
        argumentClosure(codeLinesCount: 29),
        labeledArgumentClosure(codeLinesCount: 0),
        labeledArgumentClosure(codeLinesCount: 1),
        labeledArgumentClosure(codeLinesCount: 29),
        multiLabeledArgumentClosures(codeLinesCount: 29),
        labeledAndTrailingClosures(codeLinesCount: 29),
        lazyInitialization(codeLinesCount: 28),
    ])

    static let triggeringExamples = #examples([
        trailingClosure("↓", codeLinesCount: 31, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure("↓", codeLinesCount: 31, commentLinesCount: 10, emptyLinesCount: 10),
        argumentClosure("↓", codeLinesCount: 31),
        labeledArgumentClosure("↓", codeLinesCount: 31),
        multiLabeledArgumentClosures("↓", codeLinesCount: 31),
        labeledAndTrailingClosures("↓", codeLinesCount: 31),
        lazyInitialization("↓", codeLinesCount: 29),
    ])
}

// MARK: - Private

private func singleLineClosure() -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("foo.bar { $0 }")
}

private func trailingClosure(_ violationSymbol: String = "",
                             codeLinesCount: Int,
                             commentLinesCount: Int,
                             emptyLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        foo.bar \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        \(repeatElement("\t// toto\n", count: commentLinesCount).joined())\
        \(repeatElement("\t\n", count: emptyLinesCount).joined())\
        }
        """)
}

private func argumentClosure(_ violationSymbol: String = "",
                             codeLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        foo.bar(\(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        })
        """)
}

private func labeledArgumentClosure(_ violationSymbol: String = "",
                                    codeLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        foo.bar(label: \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        })
        """)
}

private func multiLabeledArgumentClosures(_ violationSymbol: String = "",
                                          codeLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        foo.bar(label: \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        }, anotherLabel: \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        })
        """)
}

private func labeledAndTrailingClosures(_ violationSymbol: String = "",
                                        codeLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        foo.bar(label: \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        }) \(violationSymbol){ toto in
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        }
        """)
}

private func lazyInitialization(_ violationSymbol: String = "",
                                codeLinesCount: Int) -> Example {
    // No need to capture file and line here, because they are overwritten by the #examples macro.
    Example("""
        let foo: Bar = \(violationSymbol){ toto in
        \tlet bar = Bar()
        \((0..<codeLinesCount).map { "\tlet a\($0) = 0\n" }.joined())\
        \treturn bar
        }()
        """)
}
