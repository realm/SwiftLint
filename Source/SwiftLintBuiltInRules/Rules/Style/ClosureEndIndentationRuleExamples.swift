internal struct ClosureEndIndentationRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        SignalProducer(values: [1, 2, 3])
           .startWithNext { number in
               print(number)
           }
        """,
        "[1, 2].map { $0 + 1 }\n",
        """
        return match(pattern: pattern, with: [.comment]).flatMap { range in
           return Command(string: contents, range: range)
        }.flatMap { command in
           return command.expand()
        }
        """,
        """
        foo(foo: bar,
            options: baz) { _ in }
        """,
        """
        someReallyLongProperty.chainingWithAnotherProperty
           .foo { _ in }
        """,
        """
        foo(abc, 123)
        { _ in }
        """,
        """
        function(
            closure: { x in
                print(x)
            },
            anotherClosure: { y in
                print(y)
            })
        """,
        """
        function(parameter: param,
                 closure: { x in
            print(x)
        })
        """,
        """
        function(parameter: param, closure: { x in
                print(x)
            },
            anotherClosure: { y in
                print(y)
            })
        """,
        "(-variable).foo()",
        """
        let var1 = var2
            .prop?.method {
            }
            .prop!.method {
            }
            .prop[0].method {
            }
            .prop().method {
            }
        """.excludeFromDocumentation(),
        """
        #Preview("foo",
                 traits: .landscapeLeft) {
            ZStack {}
        }
        """,
    ])

    static let triggeringExamples = #examples([
        """
        SignalProducer(values: [1, 2, 3])
           .startWithNext { number in
               print(number)
        ↓}
        """,
        """
        return match(pattern: pattern, with: [.comment]).flatMap { range in
           return Command(string: contents, range: range)
           ↓}.flatMap { command in
           return command.expand()
        }
        """,
        """
        function(
            closure: { x in
                print(x)
        ↓},
            anotherClosure: { y in
                print(y)
        ↓})
        """,
    ])

    static let corrections = #examplesDictionary([
        """
        SignalProducer(values: [1, 2, 3])
            .startWithNext { number in
                print(number)
        ↓}
        """: """
            SignalProducer(values: [1, 2, 3])
                .startWithNext { number in
                    print(number)
                }
            """,
        """
        SignalProducer(values: [1, 2, 3])
            .startWithNext { number in
                print(number)
        ↓}.another { x in
                print(x)
        ↓}.yetAnother { y in
                print(y)
        ↓})
        """: """
            SignalProducer(values: [1, 2, 3])
                .startWithNext { number in
                    print(number)
                }.another { x in
                    print(x)
                }.yetAnother { y in
                    print(y)
                })
            """,
        """
        return match(pattern: pattern, with: [.comment]).flatMap { range in
        return Command(string: contents, range: range)
        ↓   }.flatMap { command in
        return command.expand()
        ↓}
        """: """
            return match(pattern: pattern, with: [.comment]).flatMap { range in
            return Command(string: contents, range: range)
            }.flatMap { command in
            return command.expand()
            }
            """,
        """
        function(
            closure: { x in
                print(x)
        ↓})
        """: """
            function(
                closure: { x in
                    print(x)
                })
            """,
        """
        function(
            closure: { x in
        ↓        print(x) })
        """: """
            function(
                closure: { x in
                    print(x) \("")
                })
            """,
        """
        function(
            closure: { x in
        ↓ab})
        """: """
            function(
                closure: { x in
            ab
                })
            """,
        """
        function(
            closure: { x in
                print(x)
        ↓},
            anotherClosure: { y in
                print(y)
            })
        """: """
            function(
                closure: { x in
                    print(x)
                },
                anotherClosure: { y in
                    print(y)
                })
            """,
        """
        function(
            closure: { x in
                print(x) // comment
                // comment
        ↓       },
            anotherClosure: { y in
                print(y)
                /* comment */})
        """: """
            function(
                closure: { x in
                    print(x) // comment
                    // comment
                },
                anotherClosure: { y in
                    print(y)
                    /* comment */
                })
            """,
        """
        function(
            closure: { x in
                print(x)
        ↓ab},
            anotherClosure: { y in
                print(y)
            })
        """: """
            function(
                closure: { x in
                    print(x)
            ab
                },
                anotherClosure: { y in
                    print(y)
                })
            """,
        """
        function(
            closure: { x in
        ↓        print(x) },
            anotherClosure: { y in
                print(y)
            })
        """: """
            function(
                closure: { x in
                    print(x) \("")
                },
                anotherClosure: { y in
                    print(y)
                })
            """,
        """
        function(
            closure: { x in
                print(x)
        ↓}, anotherClosure: { y in
            print(y)
        ↓})
        """: """
            function(
                closure: { x in
                    print(x)
                }, anotherClosure: { y in
                print(y)
            })
            """,
        """
        f {
            // do something
            ↓}
        """: """
            f {
                // do something
            }
            """,
    ])
}
