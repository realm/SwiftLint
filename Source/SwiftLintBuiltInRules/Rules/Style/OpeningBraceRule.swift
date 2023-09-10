import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule
struct OpeningBraceRule: SwiftSyntaxCorrectableRule {
    var configuration = OpeningBraceConfiguration()

    static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc() {\n}"),
            Example("[].map() { $0 }"),
            Example("[].map({ })"),
            Example("if let a = b { }"),
            Example("while a == b { }"),
            Example("guard let a = b else { }"),
            Example("struct Rule {}"),
            Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}"),
            Example("""
                    func f(rect: CGRect) {
                        {
                            let centre = CGPoint(x: rect.midX, y: rect.midY)
                            print(centre)
                        }()
                    }
                    """),
            Example("""
                    func f(rect: CGRect) -> () -> Void {
                        {
                            let centre = CGPoint(x: rect.midX, y: rect.midY)
                            print(centre)
                        }
                    }
                    """),
            Example("""
                    func f() -> () -> Void {
                        {}
                    }
                    """),
            Example("""
            class Rule:
              NSObject {
              var a: String {
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
            Example(##"let pattern = #/(\{(?<key>\w+)\})/#"##)
        ],
        triggeringExamples: [
            Example("func abc()↓{\n}"),
            Example("func abc()\n\t↓{ }"),
            Example("func abc(a: A,\n\tb: B)\n↓{"),
            Example("[].map()↓{ $0 }"),
            Example("[].map( ↓{ } )"),
            Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button(action: {
                  self.showOptions.toggle()
                })↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
            Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button(action: {
                  self.showOptions.toggle()
                })
               ↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
            Example("""
            struct OldContentView: View {
              @State private var showOptions = false

              var body: some View {
                Button {
                  self.showOptions.toggle()
                } label:↓{
                  Image(systemName: "gear")
                }
              }
            }
            """),
            Example("if let a = b↓{ }"),
            Example("while a == b↓{ }"),
            Example("guard let a = b else↓{ }"),
            Example("if\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d\n\twhere a == c↓{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else↓{ }"),
            Example("struct Rule↓{}"),
            Example("struct Rule\n↓{\n}"),
            Example("struct Rule\n\n\t↓{\n}"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}"),
            Example("switch a↓{}"),
            Example("if\n\tlet a = b,\n\tlet c = d,\n\ta == c\n↓{ }"),
            Example("while\n\tlet a = b,\n\tlet c = d,\n\ta == c\n↓{ }"),
            Example("guard\n\tlet a = b,\n\tlet c = d,\n\ta == c else\n↓{ }"),
            Example("class Rule↓{}\n"),
            Example("actor Rule↓{}\n"),
            Example("enum Rule↓{}\n"),
            Example("protocol Rule↓{}\n"),
            Example("extension Rule↓{}\n"),
            Example("""
            class Rule {
              var a: String↓{
                return ""
              }
            }
            """),
            Example("""
            class Rule {
              var a: String {
                willSet↓{

                }
                didSet  ↓{

                }
              }
            }
            """),
            Example("""
            precedencegroup Group↓{
              assignment: true
            }
            """),
            Example("""
            // Get the current thread's TLS pointer. On first call for a given thread,
            // creates and initializes a new one.
            internal static func getPointer()
              -> UnsafeMutablePointer<_ThreadLocalStorage>
            { // <- here
              return _swift_stdlib_threadLocalStorageGet().assumingMemoryBound(
                to: _ThreadLocalStorage.self)
            }
            """),
            Example("""
            func run_Array_method1x(_ N: Int) {
              let existentialArray = array!
              for _ in 0 ..< N * 100 {
                for elt in existentialArray {
                  if !elt.doIt()  {
                    fatalError("expected true")
                  }
                }
              }
            }

            func run_Array_method2x(_ N: Int) {

            }
            """),
            Example("""
               class TestFile {
                   func problemFunction() {
                       #if DEBUG
                       #endif
                   }

                   func openingBraceViolation()
                  ↓{
                       print("Brackets")
                   }
               }
            """),
            Example("""
            if
                "test".isEmpty
            ↓{
                // code here
            }
            """),
            Example("""
            func fooFun() {
                let foo: String? = "foo"
                let bar: String? = "bar"

                if
                    let foooo = foo,
                    let barrr = bar
                ↓{
                    print(foooo + barrr)
                }
            }
            """),
            Example("""
            if
                let a = ["A", "B"].first,
                let b = ["B"].first
            ↓{
                print(a)
            }
            """)
        ],
        corrections: [
            Example("struct Rule↓{}"): Example("struct Rule {}"),
            Example("struct Rule\n↓{\n}"): Example("struct Rule {\n}"),
            Example("struct Rule\n\n\t↓{\n}"): Example("struct Rule {\n}"),
            Example("struct Parent {\n\tstruct Child\n\t↓{\n\t\tlet foo: Int\n\t}\n}"):
                Example("struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}"),
            Example("[].map()↓{ $0 }"): Example("[].map() { $0 }"),
            Example("[].map( ↓{ })"): Example("[].map({ })"),
            Example("if a == b↓{ }"): Example("if a == b { }"),
            Example("if\n\tlet a = b,\n\tlet c = d↓{ }"): Example("if\n\tlet a = b,\n\tlet c = d { }"),
            Example("""
            actor MyActor  ↓{

            }
            """):
                Example("""
                actor MyActor {

                }
                """),
            Example("""
            actor MyActor
            ↓{

            }
            """):
                Example("""
            actor MyActor {

            }
            """),
            Example("""
            actor MyActor<T>  ↓{

            }
            """):
                Example("""
            actor MyActor<T> {

            }
            """),
            Example("""
            actor MyActor<T> where T: U  ↓{

            }
            """):
                Example("""
            actor MyActor<T> where T: U {

            }
            """),
            Example("""
            class Rule  ↓{

            }
            """):
                Example("""
            class Rule {

            }
            """),
            Example("""
            class Rule
            ↓{

            }
            """):
                Example("""
            class Rule {

            }
            """),
            Example("""
            class Rule<T>  ↓{

            }
            """):
                Example("""
            class Rule<T> {

            }
            """),
            Example("""
            class Rule<T>: NSObject  ↓{

            }
            """):
                Example("""
            class Rule<T>: NSObject {

            }
            """),
            Example("""
            class Rule<T>: NSObject where T: U  ↓{

            }
            """):
                Example("""
            class Rule<T>: NSObject where T: U {

            }
            """),
            Example("""
            enum Rule
            ↓{

            }
            """):
                Example("""
            enum Rule {

            }
            """),
            Example("""
            enum Rule: E  ↓{

            }
            """):
                Example("""
            enum Rule: E {

            }
            """),
            Example("""
            extension Rule
            ↓{

            }
            """):
                Example("""
            extension Rule {

            }
            """),
            Example("""
            protocol Rule  ↓{

            }
            """):
                Example("""
            protocol Rule {

            }
            """),
            Example("""
            struct Rule
            ↓{

            }
            """):
                Example("""
            struct Rule {

            }
            """),
            Example("""
            struct Rule  : A
            ↓{

            }
            """):
                Example("""
            struct Rule  : A {

            }
            """),
            Example("""
            do {

            } catch
            ↓{

            }
            """):
                Example("""
            do {

            } catch {

            }
            """),
            Example("""
            do {

            } catch MyError.unknown  ↓{

            }
            """):
                Example("""
            do {

            } catch MyError.unknown {

            }
            """),
            Example("""
            do {

            } catch let error  ↓{

            }
            """):
                Example("""
            do {

            } catch let error {

            }
            """),
            Example("""
            defer  ↓{

            }
            """):
                Example("""
            defer {

            }
            """),
            Example("""
            do  ↓{

            }
            """):
                Example("""
            do {

            }
            """),
            Example("""
            for a in b
            ↓{

            }
            """):
                Example("""
            for a in b {

            }
            """),
            Example("""
            for a in b where a == c  ↓{

            }
            """):
                Example("""
            for a in b where a == c {

            }
            """),
            Example("""
            guard a == b else
            ↓{
              return ""
            }
            """):
                Example("""
            guard a == b else {
              return ""
            }
            """),
            Example("if\n\tlet a = b,\n\tlet c = d↓{ }\n"): Example("if\n\tlet a = b,\n\tlet c = d { }\n"),
            Example("""
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self)
            ↓{ // Complex or collection type
                return .visitChildren
            }
            """):
                Example("""
            if varDecl.parent?.is(CodeBlockItemSyntax.self) == true // Local variable declaration
                || varDecl.bindings.onlyElement?.accessor != nil    // Computed property
                || !node.type.is(SimpleTypeIdentifierSyntax.self) { // Complex or collection type
                return .visitChildren
            }
            """),
            Example("""
            repeat  ↓{

            } while a
            """):
                Example("""
            repeat {

            } while a
            """),
            Example("""
            while a  ↓{

            }
            """):
                Example("""
            while a {

            }
            """),
            Example("class Rule↓{}"): Example("class Rule {}"),
            Example("actor Rule↓{}"): Example("actor Rule {}"),
            Example("enum Rule↓{}"): Example("enum Rule {}"),
            Example("protocol Rule↓{}"): Example("protocol Rule {}"),
            Example("extension Rule↓{}"): Example("extension Rule {}"),
            Example("""
            class Rule {
              var a: String {
                willSet↓{

                }
              }
            }
            """):
                Example("""
            class Rule {
              var a: String {
                willSet {

                }
              }
            }
            """),
            Example("""
            class Rule {
              var a: String {
                didSet  ↓{

                }
              }
            }
            """):
                Example("""
            class Rule {
              var a: String {
                didSet {

                }
              }
            }
            """),
            Example("""
            precedencegroup Group↓{
              assignment: true
            }
            """):
                Example("""
            precedencegroup Group {
              assignment: true
            }
            """)
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            configuration: configuration,
            disabledRegions: disabledRegions(file: file),
            locationConverter: file.locationConverter
        )
    }
}

private extension OpeningBraceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private func isMultilineFunction(_ node: FunctionDeclSyntax) -> Bool {
            guard let body = node.body else {
                return false
            }
            guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                return false
            }

            let startLocation = node.funcKeyword.endLocation(converter: locationConverter)
            let endLocation = endToken.endLocation(converter: locationConverter)
            let braceLocation = body.leftBrace.endLocation(converter: locationConverter)

            return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: CatchClauseSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: DeferStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: DoStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ForStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            guard let openingBrace = node.accessorBlock?.leftBrace else {
                return
            }
            if !openingBrace.hasSingleSpaceLeading {
                let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: PrecedenceGroupDeclSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            let openingBrace = body.leftBrace

            if configuration.allowMultilineFunc && isMultilineFunction(node) {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else {
                if openingBrace.hasSingleSpaceLeading {
                    return
                }
            }

            let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
            violations.append(violationPosition)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }

            var isMultilineFunction: Bool {
                guard let endToken = body.previousToken(viewMode: .sourceAccurate) else {
                    return false
                }

                let startLocation = node.initKeyword.endLocation(converter: locationConverter)
                let endLocation = endToken.endLocation(converter: locationConverter)
                let braceLocation = body.leftBrace.endLocation(converter: locationConverter)

                return startLocation.line != endLocation.line && endLocation.line != braceLocation.line
            }

            let openingBrace = body.leftBrace

            if configuration.allowMultilineFunc && isMultilineFunction {
                if openingBrace.hasOnlyWhitespaceInLeadingTrivia {
                    return
                }
            } else {
                if openingBrace.hasSingleSpaceLeading {
                    return
                }
            }

            let violationPosition = openingBrace.positionAfterSkippingLeadingTrivia
            violations.append(violationPosition)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let configuration: OpeningBraceConfiguration

        init(
            configuration: OpeningBraceConfiguration,
            disabledRegions: [SourceRange],
            locationConverter: SourceLocationConverter
        ) {
            self.configuration = configuration
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.extendedType))
            }

            return super.visit(node)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.genericWhereClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.primaryAssociatedTypeClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.inheritanceClause) {
                    return super.visit(fixed)
                }
                if let fixed = node.correct(keyPath: \.genericParameterClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.name))
            }

            return super.visit(node)
        }

        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.catchItems))
            }

            return super.visit(node)
        }

        override func visit(_ node: DeferStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.deferKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.doKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)

                if let fixed = node.correct(keyPath: \.whereClause) {
                    return super.visit(fixed)
                }
                return super.visit(node.correct(keyPath: \.sequence))
            }

            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.elseKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.conditions))
            }

            return super.visit(node)
        }

        override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.repeatKeyword))
            }

            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.correct(keyPath: \.conditions))
            }

            return super.visit(node)
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node
                        .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                        .with(\.leftBrace.leadingTrivia, [])
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node.with(\.accessorSpecifier, node.accessorSpecifier.with(\.trailingTrivia, .space))
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(
                    node
                        .with(\.name, node.name.with(\.trailingTrivia, .space))
                        .with(\.leftBrace, node.leftBrace.with(\.leadingTrivia, []))
                )
            }

            return super.visit(node)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.with(\.leftParen, node.leftParen?.with(\.trailingTrivia, [])))
            }

            return super.visit(node)
        }

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }
            if let violationPosition = node.violationPosition {
                correctionPositions.append(violationPosition)
                return super.visit(node.with(\.leftBrace, node.leftBrace.with(\.leadingTrivia, .space)))
            }

            return super.visit(node)
        }
    }
}

private extension DeclGroupSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = memberBlock.leftBrace
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        return nil
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T>) -> Self {
        return self
            .with(keyPath, self[keyPath: keyPath].with(\.trailingTrivia, .space))
            .with(\.memberBlock, memberBlock.with(\.leadingTrivia, []))
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T?>) -> Self? {
        guard let value = self[keyPath: keyPath] else {
            return nil
        }
        return self
            .with(keyPath, value.with(\.trailingTrivia, .space))
            .with(\.memberBlock, memberBlock.with(\.leadingTrivia, []))
    }
}

private extension WithCodeBlockSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = body.leftBrace
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        return nil
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T>) -> Self {
        return self
            .with(keyPath, self[keyPath: keyPath].with(\.trailingTrivia, .space))
            .with(\.body, body.with(\.leadingTrivia, []))
    }

    func correct<T: SyntaxProtocol>(keyPath: WritableKeyPath<Self, T?>) -> Self? {
        guard let value = self[keyPath: keyPath] else {
            return nil
        }
        return self
            .with(keyPath, value.with(\.trailingTrivia, .space))
            .with(\.body, body.with(\.leadingTrivia, []))
    }
}

private extension BracedSyntax {
    var violationPosition: AbsolutePosition? {
        if !leftBrace.hasSingleSpaceLeading {
            return leftBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension AccessorDeclSyntax {
    var violationPosition: AbsolutePosition? {
        guard let openingBrace = body?.leftBrace else {
            return nil
        }
        if !openingBrace.hasSingleSpaceLeading {
            return openingBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension PrecedenceGroupDeclSyntax {
    var violationPosition: AbsolutePosition? {
        if !leftBrace.hasSingleSpaceLeading {
            return leftBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension FunctionCallExprSyntax {
    var violationPosition: AbsolutePosition? {
        if let leftParen,
           let nextToken = leftParen.nextToken(viewMode: .sourceAccurate),
           case .leftBrace = nextToken.tokenKind {
            if !leftParen.trailingTrivia.isEmpty || !nextToken.leadingTrivia.isEmpty {
                return nextToken.positionAfterSkippingLeadingTrivia
            }
        }

        return nil
    }
}

private extension ClosureExprSyntax {
    var violationPosition: AbsolutePosition? {
        let openingBrace = leftBrace

        if let functionCall = parent?.as(FunctionCallExprSyntax.self) {
            if functionCall.calledExpression.as(ClosureExprSyntax.self) == self {
                return nil
            }
            if openingBrace.hasSingleSpaceLeading {
                return nil
            }

            return openingBrace.positionAfterSkippingLeadingTrivia
        }
        if let parent, parent.is(MultipleTrailingClosureElementSyntax.self) {
            if openingBrace.hasSingleSpaceLeading {
                return nil
            }

            return openingBrace.positionAfterSkippingLeadingTrivia
        }

        return nil
    }
}

private extension TokenSyntax {
    var hasSingleSpaceLeading: Bool {
        if let previousToken = previousToken(viewMode: .sourceAccurate),
           previousToken.trailingTrivia == .space {
            return true
        } else {
            return false
        }
    }

    var hasOnlyWhitespaceInLeadingTrivia: Bool {
        leadingTrivia.pieces.allSatisfy { $0.isWhitespace }
    }
}
// swiftlint:enable type_body_length
