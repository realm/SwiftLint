internal struct ReduceIntoInsteadOfLoopExamples {
    static let nonTriggeringExamples: [Example] = [
//        Example("""
//        class Foo {
//            static let constant: Int = 1
//            var variable: Int = 2
//        }
//        """),
//        Example("""
//        struct Foo {
//            static let constant: Int = 1
//        }
//        """),
//        Example("""
//        enum InstFooance {
//            static let constant = 1
//        }
//        """),
//        Example("""
//        struct Foo {
//            let property1
//            let property2
//            init(property1: Int, property2: String) {
//                self.property1 = property1
//                self.property2 = property2
//            }
//        }
//        """)
        Example("""
        let encountered: Set<Int> = someArray.reduce(into: Set<Int>(), { result, eachN in
            result.insert(eachN)
        })
        """)
    ]

    static let triggeringExamples: [Example] = [
//        Example("""
//        class Foo {
//            static let one = 32
//            ↓let constant: Int = 1
//        }
//        """),
//        Example("""
//        struct Foo {
//            ↓let constant: Int = 1
//        }
//        """),
//        Example("""
//        enum Foo {
//            ↓let constant: Int = 1
//        }
//        """),
        Example("""
        var encountered: Set<Int> = []
        for eachN in someArray {
            ↓encountered.insert(eachN)
        }
        """)
    ]
}

//    var encountered1: Set<Int> = []
//    var encountered1a = Set<Int>()
//    var encountered1b: Set<Int> = Set()
//    var encountered1c: Set<Int> = .init()
//    var encountered2: [String] = []
//    var encountered2a = [String]()
//    var encountered2b: [String] = [1, 2, 3, 4]
//    var encountered2c: [String] = Array<String>(contentsOf: other)
//    var encountered3: Array<String> = []
//    var encountered4: Dictionary<Int, String> = []
//    var encountered4b: [String: Int] = [:]
//    var encountered4c: [String: Int] = ["2": 2, "3": 3]
//    for eachN in someArray {
//        encountered.insert(eachN)
//        encountered1[2] = 45
//        let newSet = encountered.popFirst()
//    }
