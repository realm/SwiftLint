internal struct QuickDiscouragedFocusedTestRuleExamples {
    static let nonTriggeringExamples = [
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           describe(\"bar\") { } \n" +
        "           context(\"bar\") {\n" +
        "               it(\"bar\") { }\n" +
        "           }\n" +
        "           it(\"bar\") { }\n" +
        "           itBehavesLike(\"bar\")\n" +
        "       }\n" +
        "   }\n" +
        "}\n"
    ]

    static let triggeringExamples = [
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓fdescribe(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓fcontext(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓fit(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           ↓fit(\"bar\") { }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       context(\"foo\") {\n" +
        "           ↓fit(\"bar\") { }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           context(\"bar\") {\n" +
        "               ↓fit(\"toto\") { }\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓fitBehavesLike(\"foo\")\n" +
        "   }\n" +
        "}\n"
    ]
}
