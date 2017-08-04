//
//  ClosureBodyLengthRuleExamples.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/4/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

internal struct ClosureBodyLengthRuleExamples {
    static let nonTriggeringExamples: [String] = [
        singleLineClosure(),
        trailingClosure(codeLinesCount: 0, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure(codeLinesCount: 1, commentLinesCount: 10, emptyLinesCount: 10),
        trailingClosure(codeLinesCount: 19, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure(codeLinesCount: 19, commentLinesCount: 10, emptyLinesCount: 10),
        argumentClosure(codeLinesCount: 0),
        argumentClosure(codeLinesCount: 1),
        argumentClosure(codeLinesCount: 19),
        labeledArgumentClosure(codeLinesCount: 0),
        labeledArgumentClosure(codeLinesCount: 1),
        labeledArgumentClosure(codeLinesCount: 19),
        multiLabeledArgumentClosures(codeLinesCount: 19),
        labeledAndTrailingClosures(codeLinesCount: 19),
        lazyInitialization(codeLinesCount: 18)
    ]

    static let triggeringExamples: [String] = [
        trailingClosure("↓", codeLinesCount: 22, commentLinesCount: 0, emptyLinesCount: 0),
        trailingClosure("↓", codeLinesCount: 22, commentLinesCount: 10, emptyLinesCount: 10),
        argumentClosure("↓", codeLinesCount: 22),
        labeledArgumentClosure("↓", codeLinesCount: 22),
        multiLabeledArgumentClosures("↓", codeLinesCount: 22),
        labeledAndTrailingClosures("↓", codeLinesCount: 22),
        lazyInitialization("↓", codeLinesCount: 19)
    ]
}

// MARK: - Private

private func singleLineClosure() -> String {
    return "foo.bar { $0 }"
}

private func trailingClosure(_ violationSymbol: String = "",
                             codeLinesCount: Int,
                             commentLinesCount: Int,
                             emptyLinesCount: Int) -> String {
    return "foo.bar {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
        repeatElement("\t// toto\n", count: commentLinesCount).joined() +
        repeatElement("\t\n", count: emptyLinesCount).joined() +
    "}"
}

private func argumentClosure(_ violationSymbol: String = "", codeLinesCount: Int) -> String {
    return "foo.bar({" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
    "})"
}

private func labeledArgumentClosure(_ violationSymbol: String = "", codeLinesCount: Int) -> String {
    return "foo.bar(label: {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
    "})"
}

private func multiLabeledArgumentClosures(_ violationSymbol: String = "", codeLinesCount: Int) -> String {
    return "foo.bar(label: {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
        "}, anotherLabel: {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
    "})"
}

private func labeledAndTrailingClosures(_ violationSymbol: String = "", codeLinesCount: Int) -> String {
    return "foo.bar(label: {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
        "}) {" + violationSymbol + "\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
    "}"
}

private func lazyInitialization(_ violationSymbol: String = "", codeLinesCount: Int) -> String {
    return "let foo: Bar = {" + violationSymbol + "\n" +
        "\tlet bar = Bar()\n" +
        repeatElement("\tlet a = 0\n", count: codeLinesCount).joined() +
        "\treturn bar\n" +
    "}()"
}
