// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
struct ContrastedOpeningBraceRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
            func abc()
            {
            }
            """),
        Example("""
            [].map()
            {
                $0
            }
            """),
        Example("""
            [].map(
                {
                }
            )
            """),
        Example("""
            if let a = b
            {
            }
            """),
        Example("""
            while a == b
            {
            }
            """),
        Example("""
            guard let a = b else
            {
            }
            """),
        Example("""
            struct Rule
            {
            }
            """),
        Example("""
            struct Parent
            {
                struct Child
                {
                    let foo: Int
                }
            }
            """),
        Example("""
            func f(rect: CGRect)
            {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }()
            }
            """),
        Example("""
            func f(rect: CGRect) -> () -> Void
            {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }
            }
            """),
        Example("""
            func f() -> () -> Void
            {
                {}
            }
            """),
        Example("""
            @MyProperty class Rule:
              NSObject
            {
              var a: String
              {
                return ""
              }
            }
            """),
        Example("""
            self.foo(
                (
                    "String parameter",
                    { "Do something here" }
                )
            )
            """),
        Example(##"let pattern = #/(\{(?<key>\w+)\})/#"##),
        Example("""
            if c
            {}
            else
            {}
            """),
        Example("""
            if c /* comment */
            {
                return
            }
        """),
        Example("""
            if c1
            {
              return
            } else if c2
            {
              return
            } else if c3
            {
              return
            }
            """),
        Example("""
            let a = f.map
            { a in
                a
            }
            """),
    ]

    static let triggeringExamples = [
        Example("""
            func abc()↓{
            }
            """),
        Example("""
            func abc() { }
            """),
        Example("""
            func abc(a: A,
                     b: B) {}
            """),
        Example("""
            [].map { $0 }
            """),
        Example("""
            struct OldContentView: View ↓{
              @State private var showOptions = false

              var body: some View ↓{
                Button(action: {
                  self.showOptions.toggle()
                })↓{
                  Image(systemName: "gear")
                } label: ↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
        Example("""
            class Rule
            {
              var a: String↓{
                return ""
              }
            }
            """),
        Example("""
            @MyProperty class Rule
            {
              var a: String
              {
                willSet↓{

                }
                didSet  ↓{

                }
              }
            }
            """),
        Example("""
            precedencegroup Group ↓{
              assignment: true
            }
            """),
        Example("""
            class TestFile
            {
               func problemFunction() ↓{
                   #if DEBUG
                   #endif
               }

               func openingBraceViolation()
               {
                   print("Brackets")
               }
            }
            """, excludeFromDocumentation: true),
        Example("""
            if
                "test".isEmpty ↓{
                // code here
            }
            """),
        Example("""
            if c  ↓{}
            else /* comment */  ↓{}
            """),
        Example("""
            if c
              ↓{
                // code here
            }
            """),
        Example("""
            if c1 ↓{
              return
            } else if c2↓{
              return
            } else if c3
             ↓{
              return
            }
            """),
        Example("""
            func f()
            {
                return a.map
                        ↓{ $0 }
            }
            """),
        Example("""
            a ↓{
                $0
            } b: ↓{
                $1
            }
            """),
    ]

    static let corrections = [
        Example("""
            struct Rule{}
            """): Example("""
                struct Rule
                {}
                """),
        Example("""
            struct Parent {
                struct Child {
                    let foo: Int
                }
            }
            """): Example("""
                struct Parent
                {
                    struct Child
                    {
                        let foo: Int
                    }
                }
                """),
        Example("""
            [].map(){ $0 }
            """): Example("""
                [].map()
                { $0 }
                """),
        Example("""
            if a == b{ }
            """): Example("""
                if a == b
                { }
                """),
        Example("""
            @MyProperty actor MyActor<T>  {

            }
            """): Example("""
                @MyProperty actor MyActor<T>
                {

                }
                """),
        Example("""
            actor MyActor<T> where T: U  {

            }
            """): Example("""
                actor MyActor<T> where T: U
                {

                }
                """),
        Example("""
            do {

            } catch              {

            }
            """): Example("""
                do
                {

                } catch
                {

                }
                """),
        Example("""
            do {

            } catch MyError.unknown  {

            }
            """): Example("""
                do
                {

                } catch MyError.unknown
                {

                }
                """),
        Example("""
            defer  {

            }
            """): Example("""
                defer
                {

                }
                """),
        Example("""
            for a in b where a == c {

            }
            """): Example("""
                for a in b where a == c
                {

                }
                """),
        Example("""
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self) { // Complex or collection type
                return .visitChildren
            }
            """): Example("""
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                    || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                    || !node.type.is(SimpleTypeIdentifierSyntax.self)
                { // Complex or collection type
                    return .visitChildren
                }
                """),
        Example("""
            @MyProperty class Rule
            {
              var a: String {
                didSet  {

                }
              }
            }
            """): Example("""
                @MyProperty class Rule
                {
                  var a: String
                  {
                    didSet
                    {

                    }
                  }
                }
                """),
        Example("""
            precedencegroup Group{
              assignment: true
            }
            """): Example("""
                precedencegroup Group
                {
                  assignment: true
                }
                """),
        Example("""
            if c /* comment */    {
                return
            }
            """): Example("""
                if c /* comment */
                {
                    return
                }
                """),
        Example("""
            func foo() {
                if q1, q2 {
                    do1()
                } else if q3, q4 {
                    do2()
                }
            }
            """): Example("""
                func foo()
                {
                    if q1, q2
                    {
                        do1()
                    } else if q3, q4
                    {
                        do2()
                    }
                }
                """),
        Example("""
            if
                "test".isEmpty
            // swiftlint:disable:next contrasted_opening_brace
              {
                // code here
            }
            """): Example("""
                if
                    "test".isEmpty
                // swiftlint:disable:next contrasted_opening_brace
                  {
                    // code here
                }
                """),
        Example("""
            private func f()
                // comment
            {
                let a = 1
            }
            """): Example("""
                private func f()
                    // comment
                {
                    let a = 1
                }
                """),
        Example("""
            while true /* endless loop */ {
                // nothing
            }
            """): Example("""
                while true /* endless loop */
                {
                    // nothing
                }
                """),
        Example("""
            a.b { $0 }
             .c { $1 }
            """): Example("""
                a.b
                { $0 }
                 .c
                 { $1 }
                """),
        Example("""
            a {
                $0
            } b: {
                $1
            }
            """): Example("""
                a
                {
                    $0
                } b:
                {
                    $1
                }
                """),
    ]
}
