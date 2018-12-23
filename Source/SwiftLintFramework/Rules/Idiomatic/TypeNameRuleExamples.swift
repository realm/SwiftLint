internal struct TypeNameRuleExamples {
    private static let types = ["class", "struct", "enum"]

    static let nonTriggeringExamples: [String] = {
        let typeExamples: [String] = types.flatMap { (type: String) -> [String] in
            [
                "\(type) MyType {}",
                "private \(type) _MyType {}",
                "\(type) \(repeatElement("A", count: 40).joined()) {}"
            ]
        }
        let typeAliasAndAssociatedTypeExamples = [
            "typealias Foo = Void",
            "private typealias Foo = Void",
            """
            protocol Foo {
              associatedtype Bar
            }
            """,
            """
            protocol Foo {
              associatedtype Bar: Equatable
            }
            """
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples + ["enum MyType {\ncase value\n}"]
    }()

    static let triggeringExamples: [String] = {
        let typeExamples: [String] = types.flatMap { (type: String) -> [String] in
            [
                "\(type) ↓myType {}",
                "\(type) ↓_MyType {}",
                "private \(type) ↓MyType_ {}",
                "\(type) ↓My {}",
                "\(type) ↓\(repeatElement("A", count: 41).joined()) {}"
            ]
        }
        let typeAliasAndAssociatedTypeExamples: [String] = [
            "typealias ↓X = Void",
            "private typealias ↓Foo_Bar = Void",
            "private typealias ↓foo = Void",
            "typealias ↓\(repeatElement("A", count: 41).joined()) = Void",
            """
            protocol Foo {
              associatedtype ↓X
            }
            """,
            """
            protocol Foo {
              associatedtype ↓Foo_Bar: Equatable
            }
            """,
            """
            protocol Foo {
              associatedtype ↓\(repeatElement("A", count: 41).joined())
            }
            """
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples
    }()
}
