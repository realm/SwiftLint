internal struct QuickDiscouragedPendingTestRuleExamples {
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
        "       ↓xdescribe(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓xcontext(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓xit(\"foo\") { }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           ↓xit(\"bar\") { }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       context(\"foo\") {\n" +
        "           ↓xit(\"bar\") { }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           context(\"bar\") {\n" +
        "               ↓xit(\"toto\") { }\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓pending(\"foo\")\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       ↓xitBehavesLike(\"foo\")\n" +
        "   }\n" +
        "}\n"
    ]
}
