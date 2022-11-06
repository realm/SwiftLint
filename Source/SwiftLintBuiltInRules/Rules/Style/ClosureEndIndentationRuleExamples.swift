internal struct ClosureEndIndentationRuleExamples {
    static let nonTriggeringExamples = [
        Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }\n"),
        Example("[1, 2].map { $0 + 1 }\n"),
        Example("return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "}\n"),
        Example("foo(foo: bar,\n" +
        "    options: baz) { _ in }\n"),
        Example("someReallyLongProperty.chainingWithAnotherProperty\n" +
        "   .foo { _ in }"),
        Example("foo(abc, 123)\n" +
        "{ _ in }\n"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("function(parameter: param,\n" +
        "         closure: { x in\n" +
        "    print(x)\n" +
        "})"),
        Example("function(parameter: param, closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("(-variable).foo()")
    ]

    static let triggeringExamples = [
        Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}\n"),
        Example("return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "   ↓}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "↓}\n"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "↓})")
    ]

    static let corrections = [
        Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}\n"): Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }\n"),
        Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}.another { x in\n" +
        "       print(x)\n" +
        "↓}.yetAnother { y in\n" +
        "       print(y)\n" +
        "↓})"): Example("SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }.another { x in\n" +
        "       print(x)\n" +
        "   }.yetAnother { y in\n" +
        "       print(y)\n" +
        "   })"),
        Example("return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "↓   }.flatMap { command in\n" +
        "   return command.expand()\n" +
        "↓}\n"): Example("return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "}\n"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓})"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "↓        print(x) })"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x) \n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "↓ab})"): Example("function(\n" +
        "    closure: { x in\n" +
        "ab\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓       },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓ab},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "ab\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "↓        print(x) },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x) \n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"),
        Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓}, anotherClosure: { y in\n" +
        "    print(y)\n" +
        "↓})"): Example("function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    }, anotherClosure: { y in\n" +
        "    print(y)\n" +
        "    })")
    ]
}
