struct ReduceIntoInsteadOfLoopRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("""
            let result: [SomeType] = someSequence.reduce(into: [], { result, eachN in
                result.insert(eachN)
            })
        """),
        Example("""
            let result: Set<SomeType> = someSequence.reduce(into: []], { result, eachN in
                result.insert(eachN)
            })
        """),
        Example("""
            let result: [SomeType1: SomeType2] = someSequence.reduce(into: [:], { result, eachN in
                result[SomeType1Value] = SomeType2Value
            })
        """),
    ]

    static let triggeringExamples: [Example] =
          triggeringArrayExamples
        + triggeringSetExamples
        + triggeringDictionaryExamples
}

extension ReduceIntoInsteadOfLoopRuleExamples {
    private static let triggeringDictionaryExamples: [Example] = [
        Example("""
            var result: Dictionary<SomeType1, SomeType2> = [:]
            for eachN in someSequence {
                ↓result[SomeType1Value] = SomeType2Value + eachN
            }
        """),
        Example("""
            var result: Dictionary<SomeType1, SomeType2> = [:]
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result: Dictionary<SomeType1, SomeType2> = .init()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result = Dictionary<SomeType1, SomeType2>()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
    ]

    private static let triggeringSetExamples: [Example] = [
        Example("""
            var result: Set<SomeType> = []
            for eachN in someSequence {
                ↓result = result + [eachN]
            }
        """),
        Example("""
            var result: Set<SomeType> = []
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result: Set<SomeType> = .init()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result = Set<SomeType>()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
    ]

    private static let triggeringArrayExamples: [Example] = [
        Example("""
            var result: [SomeType] = []
            for eachN in someSequence {
                ↓result[5] = eachN
            }
        """),
        Example("""
            var result: [SomeType] = []
            for eachN in someSequence {
                ↓result = result + [eachN]
            }
        """),
        Example("""
            var result: [SomeType] = []
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result: [SomeType] = .init()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result = Array<SomeType>()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
        Example("""
            var result = [SomeType]()
            for eachN in someSequence {
                ↓result.someMethod(eachN)
            }
        """),
    ]
}
