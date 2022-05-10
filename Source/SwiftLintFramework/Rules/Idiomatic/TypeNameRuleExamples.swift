internal struct TypeNameRuleExamples {
    private static let types = ["class", "struct", "enum"]

    static let nonTriggeringExamples: [Example] = {
        let typeExamples: [Example] = types.flatMap { type -> [Example] in
            [
                Example("\(type) MyType {}"),
                Example("private \(type) _MyType {}"),
                Example("\(type) \(repeatElement("A", count: 40).joined()) {}"),
                Example("\(type) MyView_Previews: PreviewProvider"),
                Example("private \(type) _MyView_Previews: PreviewProvider")
            ]
        }

        let typeAliasAndAssociatedTypeExamples: [Example] = [
            Example("typealias Foo = Void"),
            Example("private typealias Foo = Void"),
            Example("""
            protocol Foo {
              associatedtype Bar
            }
            """),
            Example("""
            protocol Foo {
              associatedtype Bar: Equatable
            }
            """)
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples + [Example("enum MyType {\ncase value\n}")]
    }()

    static let triggeringExamples: [Example] = {
        let typeExamples: [Example] = types.flatMap { type in
            [
                Example("\(type) ↓myType {}"),
                Example("\(type) ↓_MyType {}"),
                Example("private \(type) ↓MyType_ {}"),
                Example("private \(type) ↓`_` {}", excludeFromDocumentation: true),
                Example("\(type) ↓My {}"),
                Example("\(type) ↓\(repeatElement("A", count: 41).joined()) {}"),
                Example("\(type) ↓MyView_Previews"),
                Example("private \(type) ↓_MyView_Previews"),
                Example("\(type) ↓MyView_Previews_Previews: PreviewProvider")
            ]
        }

        let typeAliasAndAssociatedTypeExamples: [Example] = [
            Example("typealias ↓X = Void"),
            Example("private typealias ↓Foo_Bar = Void"),
            Example("private typealias ↓foo = Void"),
            Example("typealias ↓\(repeatElement("A", count: 41).joined()) = Void"),
            Example("""
            protocol Foo {
              associatedtype ↓X
            }
            """),
            Example("""
            protocol Foo {
              associatedtype ↓Foo_Bar: Equatable
            }
            """),
            Example("""
            protocol Foo {
              associatedtype ↓\(repeatElement("A", count: 41).joined())
            }
            """)
        ]

        return typeExamples + typeAliasAndAssociatedTypeExamples
    }()
}
