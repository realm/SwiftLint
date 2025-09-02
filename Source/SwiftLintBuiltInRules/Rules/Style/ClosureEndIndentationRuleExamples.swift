internal struct ClosureEndIndentationRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        SignalProducer(values: [1, 2, 3])
           .startWithNext { number in
               print(number)
           }
        """),
        Example("[1, 2].map { $0 + 1 }\n"),
        Example("""
        return match(pattern: pattern, with: [.comment]).flatMap { range in
           return Command(string: contents, range: range)
        }.flatMap { command in
           return command.expand()
        }
        """),
        Example("""
        foo(foo: bar,
            options: baz) { _ in }
        """),
        Example("""
        someReallyLongProperty.chainingWithAnotherProperty
           .foo { _ in }
        """),
        Example("""
        foo(abc, 123)
        { _ in }
        """),
        Example("""
        function(
            closure: { x in
                print(x)
            },
            anotherClosure: { y in
                print(y)
            })
        """),
        Example("""
        function(parameter: param,
                 closure: { x in
            print(x)
        })
        """),
        Example("""
        function(parameter: param, closure: { x in
                print(x)
            },
            anotherClosure: { y in
                print(y)
            })
        """),
        Example("(-variable).foo()"),
        Example("""
        let var1 = var2
            .prop?.method {
            }
            .prop!.method {
            }
            .prop[0].method {
            }
            .prop().method {
            }
        """, excludeFromDocumentation: true),
    ]

    static let triggeringExamples = [
        Example("""
        SignalProducer(values: [1, 2, 3])
           .startWithNext { number in
               print(number)
        ↓}
        """),
        Example("""
        return match(pattern: pattern, with: [.comment]).flatMap { range in
           return Command(string: contents, range: range)
           ↓}.flatMap { command in
           return command.expand()
        }
        """),
        Example("""
        function(
            closure: { x in
                print(x)
        ↓},
            anotherClosure: { y in
                print(y)
        ↓})
        """),
    ]

    static let corrections = [
        Example("""
        SignalProducer(values: [1, 2, 3])
            .startWithNext { number in
                print(number)
        ↓}
        """): Example("""
            SignalProducer(values: [1, 2, 3])
                .startWithNext { number in
                    print(number)
                }
            """),
        Example("""
        SignalProducer(values: [1, 2, 3])
            .startWithNext { number in
                print(number)
        ↓}.another { x in
                print(x)
        ↓}.yetAnother { y in
                print(y)
        ↓})
        """): Example("""
            SignalProducer(values: [1, 2, 3])
                .startWithNext { number in
                    print(number)
                }.another { x in
                    print(x)
                }.yetAnother { y in
                    print(y)
                })
            """),
        Example("""
        return match(pattern: pattern, with: [.comment]).flatMap { range in
        return Command(string: contents, range: range)
        ↓   }.flatMap { command in
        return command.expand()
        ↓}
        """): Example("""
            return match(pattern: pattern, with: [.comment]).flatMap { range in
            return Command(string: contents, range: range)
            }.flatMap { command in
            return command.expand()
            }
            """),
        Example("""
        function(
            closure: { x in
                print(x)
        ↓})
        """): Example("""
            function(
                closure: { x in
                    print(x)
                })
            """),
        Example("""
        function(
            closure: { x in
        ↓        print(x) })
        """): Example("""
            function(
                closure: { x in
                    print(x) \("")
                })
            """),
        Example("""
        function(
            closure: { x in
        ↓ab})
        """): Example("""
            function(
                closure: { x in
            ab
                })
            """),
        Example("""
        function(
            closure: { x in
                print(x)
        ↓},
            anotherClosure: { y in
                print(y)
            })
        """): Example("""
            function(
                closure: { x in
                    print(x)
                },
                anotherClosure: { y in
                    print(y)
                })
            """),
        Example("""
        function(
            closure: { x in
                print(x) // comment
                // comment
        ↓       },
            anotherClosure: { y in
                print(y)
                /* comment */})
        """): Example("""
            function(
                closure: { x in
                    print(x) // comment
                    // comment
                },
                anotherClosure: { y in
                    print(y)
                    /* comment */
                })
            """),
        Example("""
        function(
            closure: { x in
                print(x)
        ↓ab},
            anotherClosure: { y in
                print(y)
            })
        """): Example("""
            function(
                closure: { x in
                    print(x)
            ab
                },
                anotherClosure: { y in
                    print(y)
                })
            """),
        Example("""
        function(
            closure: { x in
        ↓        print(x) },
            anotherClosure: { y in
                print(y)
            })
        """): Example("""
            function(
                closure: { x in
                    print(x) \("")
                },
                anotherClosure: { y in
                    print(y)
                })
            """),
        Example("""
        function(
            closure: { x in
                print(x)
        ↓}, anotherClosure: { y in
            print(y)
        ↓})
        """): Example("""
            function(
                closure: { x in
                    print(x)
                }, anotherClosure: { y in
                print(y)
            })
            """),
        Example("""
        f {
            // do something
            ↓}
        """): Example("""
            f {
                // do something
            }
            """),
    ]
}
