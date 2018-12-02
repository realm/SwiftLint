internal struct ClosureEndIndentationRuleExamples {
    static let nonTriggeringExamples = [
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }\n",
        "[1, 2].map { $0 + 1 }\n",
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "}\n",
        "foo(foo: bar,\n" +
        "    options: baz) { _ in }\n",
        "someReallyLongProperty.chainingWithAnotherProperty\n" +
        "   .foo { _ in }",
        "foo(abc, 123)\n" +
        "{ _ in }\n",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(parameter: param,\n" +
        "         closure: { x in\n" +
        "    print(x)\n" +
        "})",
        "function(parameter: param, closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"
    ]

    static let triggeringExamples = [
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}\n",
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "   ↓}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "↓}\n",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "↓})"
    ]

    static let corrections = [
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}\n":
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }\n",
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}.another { x in\n" +
        "       print(x)\n" +
        "↓}.yetAnother { y in\n" +
        "       print(y)\n" +
        "↓})":
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }.another { x in\n" +
        "       print(x)\n" +
        "   }.yetAnother { y in\n" +
        "       print(y)\n" +
        "   })",
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "↓   }.flatMap { command in\n" +
        "   return command.expand()\n" +
        "↓}\n":
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "}\n",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓})":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "↓        print(x) })":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x) \n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "↓ab})":
        "function(\n" +
        "    closure: { x in\n" +
        "ab\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓       },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓ab},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "ab\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "↓        print(x) },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x) \n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓}, anotherClosure: { y in\n" +
        "    print(y)\n" +
        "↓})":
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    }, anotherClosure: { y in\n" +
        "    print(y)\n" +
        "    })"
    ]
}
