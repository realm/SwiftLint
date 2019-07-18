internal struct TypeNameRuleExamples {
    private static let types = ["class", "struct", "enum"]

    static let nonTriggeringExamples: [String] = {
        let typeExamples: [String] = types.flatMap { type -> [String] in
            [
                "\(type) MyType {}",
                "private \(type) _MyType {}",
                "\(type) \(repeatElement("A", count: 40).joined()) {}",
                "\(type) MyView_Previews: PreviewProvider",
                "private \(type) _MyView_Previews: PreviewProvider"
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
        let typeExamples: [String] = types.flatMap { type in
            [
                "\(type) ↓myType {}",
                "\(type) ↓_MyType {}",
                "private \(type) ↓MyType_ {}",
                "\(type) ↓My {}",
                "\(type) ↓\(repeatElement("A", count: 41).joined()) {}",
                "\(type) ↓MyView_Previews",
                "private \(type) ↓_MyView_Previews",
                "\(type) ↓MyView_Previews_Previews: PreviewProvider"
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
