// swiftlint:disable type_body_length

internal struct QuickDiscouragedCallRuleExamples {
    static let nonTriggeringExamples: [String] = [
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           beforeEach {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           beforeEach {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "           afterEach {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "           describe(\"bar\") {\n" +
        "           }\n" +
        "           context(\"bar\") {\n" +
        "           }\n" +
        "           it(\"bar\") {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "          itBehavesLike(\"bar\")\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           it(\"does something\") {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       context(\"foo\") {\n" +
        "           afterEach { toto.append(foo) }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       xcontext(\"foo\") {\n" +
        "           afterEach { toto.append(foo) }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       xdescribe(\"foo\") {\n" +
        "           afterEach { toto.append(foo) }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           xit(\"does something\") {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       fcontext(\"foo\") {\n" +
        "           afterEach { toto.append(foo) }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       fdescribe(\"foo\") {\n" +
        "           afterEach { toto.append(foo) }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           fit(\"does something\") {\n" +
        "               let foo = Foo()\n" +
        "               foo.toto()\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       fitBehavesLike(\"foo\")\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       xitBehavesLike(\"foo\")\n" +
        "   }\n" +
        "}\n"
    ]

    static let triggeringExamples: [String]  = [
        "class TotoTests {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           let foo = Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n" +
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           context(\"foo\") {\n" +
        "               let foo = ↓Foo()\n" +
        "           }\n" +
        "           context(\"bar\") {\n" +
        "               let foo = ↓Foo()\n" +
        "               ↓foo.bar()\n" +
        "               it(\"does something\") {\n" +
        "                   let foo = Foo()\n" +
        "                   foo.toto()\n" +
        "               }\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           context(\"foo\") {\n" +
        "               context(\"foo\") {\n" +
        "                   beforeEach {\n" +
        "                       let foo = Foo()\n" +
        "                       foo.toto()\n" +
        "                   }\n" +
        "                   it(\"bar\") {\n" +
        "                   }\n" +
        "                   context(\"foo\") {\n" +
        "                       let foo = ↓Foo()\n" +
        "                   }\n" +
        "               }\n" +
        "           }\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       context(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       sharedExamples(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       describe(\"foo\") {\n" +
        "           ↓foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       context(\"foo\") {\n" +
        "           ↓foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       sharedExamples(\"foo\") {\n" +
        "           ↓foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       xdescribe(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "       fdescribe(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n",
        "class TotoTests: QuickSpec {\n" +
        "   override func spec() {\n" +
        "       xcontext(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "       fcontext(\"foo\") {\n" +
        "           let foo = ↓Foo()\n" +
        "       }\n" +
        "   }\n" +
        "}\n"
    ]
}
