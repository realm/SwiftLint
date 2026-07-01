// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
struct ContrastedOpeningBraceRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
            func abc()
            {
            }
            """,
        """
            [].map()
            {
                $0
            }
            """,
        """
            [].map(
                {
                }
            )
            """,
        """
            if let a = b
            {
            }
            """,
        """
            while a == b
            {
            }
            """,
        """
            guard let a = b else
            {
            }
            """,
        """
            struct Rule
            {
            }
            """,
        """
            struct Parent
            {
                struct Child
                {
                    let foo: Int
                }
            }
            """,
        """
            func f(rect: CGRect)
            {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }()
            }
            """,
        """
            func f(rect: CGRect) -> () -> Void
            {
                {
                    let centre = CGPoint(x: rect.midX, y: rect.midY)
                    print(centre)
                }
            }
            """,
        """
            func f() -> () -> Void
            {
                {}
            }
            """,
        """
            @MyProperty class Rule:
              NSObject
            {
              var a: String
              {
                return ""
              }
            }
            """,
        """
            self.foo(
                (
                    "String parameter",
                    { "Do something here" }
                )
            )
            """,
        ##"let pattern = #/(\{(?<key>\w+)\})/#"##,
        """
            if c
            {}
            else
            {}
            """,
        """
            if c /* comment */
            {
                return
            }
        """,
        """
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
            """,
        """
            let a = f.map
            { a in
                a
            }
            """,
    ])

    static let triggeringExamples = #examples([
        """
            func abc()↓{
            }
            """,
        """
            func abc() { }
            """,
        """
            func abc(a: A,
                     b: B) {}
            """,
        """
            [].map { $0 }
            """,
        """
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
            """,
        """
            class Rule
            {
              var a: String↓{
                return ""
              }
            }
            """,
        """
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
            """,
        """
            precedencegroup Group ↓{
              assignment: true
            }
            """,
        """
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
            """.excludeFromDocumentation(),
        """
            if
                "test".isEmpty ↓{
                // code here
            }
            """,
        """
            if c  ↓{}
            else /* comment */  ↓{}
            """,
        """
            if c
              ↓{
                // code here
            }
            """,
        """
            if c1 ↓{
              return
            } else if c2↓{
              return
            } else if c3
             ↓{
              return
            }
            """,
        """
            func f()
            {
                return a.map
                        ↓{ $0 }
            }
            """,
        """
            a ↓{
                $0
            } b: ↓{
                $1
            }
            """,
    ])

    static let corrections = #corrections([
        """
            struct Rule{}
            """: """
                struct Rule
                {}
                """,
        """
            struct Parent {
                struct Child {
                    let foo: Int
                }
            }
            """: """
                struct Parent
                {
                    struct Child
                    {
                        let foo: Int
                    }
                }
                """,
        """
            [].map(){ $0 }
            """: """
                [].map()
                { $0 }
                """,
        """
            if a == b{ }
            """: """
                if a == b
                { }
                """,
        """
            @MyProperty actor MyActor<T>  {

            }
            """: """
                @MyProperty actor MyActor<T>
                {

                }
                """,
        """
            actor MyActor<T> where T: U  {

            }
            """: """
                actor MyActor<T> where T: U
                {

                }
                """,
        """
            do {

            } catch              {

            }
            """: """
                do
                {

                } catch
                {

                }
                """,
        """
            do {

            } catch MyError.unknown  {

            }
            """: """
                do
                {

                } catch MyError.unknown
                {

                }
                """,
        """
            defer  {

            }
            """: """
                defer
                {

                }
                """,
        """
            for a in b where a == c {

            }
            """: """
                for a in b where a == c
                {

                }
                """,
        """
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self) { // Complex or collection type
                return .visitChildren
            }
            """: """
                if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                    || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                    || !node.type.is(SimpleTypeIdentifierSyntax.self)
                { // Complex or collection type
                    return .visitChildren
                }
                """,
        """
            @MyProperty class Rule
            {
              var a: String {
                didSet  {

                }
              }
            }
            """: """
                @MyProperty class Rule
                {
                  var a: String
                  {
                    didSet
                    {

                    }
                  }
                }
                """,
        """
            precedencegroup Group{
              assignment: true
            }
            """: """
                precedencegroup Group
                {
                  assignment: true
                }
                """,
        """
            if c /* comment */    {
                return
            }
            """: """
                if c /* comment */
                {
                    return
                }
                """,
        """
            func foo() {
                if q1, q2 {
                    do1()
                } else if q3, q4 {
                    do2()
                }
            }
            """: """
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
                """,
        """
            if
                "test".isEmpty
            // swiftlint:disable:next contrasted_opening_brace
              {
                // code here
            }
            """: """
                if
                    "test".isEmpty
                // swiftlint:disable:next contrasted_opening_brace
                  {
                    // code here
                }
                """,
        """
            private func f()
                // comment
            {
                let a = 1
            }
            """: """
                private func f()
                    // comment
                {
                    let a = 1
                }
                """,
        """
            while true /* endless loop */ {
                // nothing
            }
            """: """
                while true /* endless loop */
                {
                    // nothing
                }
                """,
        """
            a.b { $0 }
             .c { $1 }
            """: """
                a.b
                { $0 }
                 .c
                 { $1 }
                """,
        """
            a {
                $0
            } b: {
                $1
            }
            """: """
                a
                {
                    $0
                } b:
                {
                    $1
                }
                """,
    ])
}
