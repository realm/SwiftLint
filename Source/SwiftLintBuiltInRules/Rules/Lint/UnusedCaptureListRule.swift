import SwiftSyntax

// TODO: [12/22/2024] Remove deprecation warning after ~2 years.
private let warnDeprecatedOnceImpl: Void = {
    Issue.ruleDeprecated(ruleID: UnusedCaptureListRule.description.identifier).print()
}()

private func warnDeprecatedOnce() {
    _ = warnDeprecatedOnceImpl
}

@SwiftSyntaxRule(deprecated: true)
struct UnusedCaptureListRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description = RuleDescription(
        identifier: "unused_capture_list",
        name: "Unused Capture List",
        description: "Unused reference in a capture list should be removed",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            [1, 2].map {
                [ weak
                  delegate,
                  unowned
                  self
                ] num in
                delegate.handle(num)
            }
            """),
            Example("""
            [1, 2].map { [weak self] num in
                self?.handle(num)
            }
            """),
            Example("""
            let failure: Failure = { [weak self, unowned delegate = self.delegate!] foo in
                delegate.handle(foo, self)
            }
            """),
            Example("""
            numbers.forEach({
                [weak handler] in
                handler?.handle($0)
            })
            """),
            Example("""
            withEnvironment(apiService: MockService(fetchProjectResponse: project)) {
                [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
                    device.handle()
                }
            }
            """),
            Example("{ [foo] _ in foo.bar() }()"),
            Example("sizes.max().flatMap { [(offset: offset, size: $0)] } ?? []"),
            Example("""
            [1, 2].map { [self] num in
                handle(num)
            }
            """),
            Example("""
            [1, 2].map { [unowned self] num in
                handle(num)
            }
            """),
            Example("""
            [1, 2].map { [self, unowned delegate = self.delegate!] num in
                delegate.handle(num)
            }
            """),
            Example("""
            [1, 2].map { [unowned self, unowned delegate = self.delegate!] num in
                delegate.handle(num)
            }
            """),
            Example("""
            [1, 2].map {
                [ weak
                  delegate,
                  self
                ] num in
                delegate.handle(num)
            }
            """),
            Example("""
            rx.onViewDidAppear.subscribe(onNext: { [unowned self] in
                  doSomething()
            }).disposed(by: disposeBag)
            """),
            Example("""
            let closure = { [weak self] in
                guard let self else {
                    return
                }
                someInstanceFunction()
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            [1, 2].map { [↓weak self] num in
                print(num)
            }
            """),
            Example("""
            let failure: Failure = { [weak self, ↓unowned delegate = self.delegate!] foo in
                self?.handle(foo)
            }
            """),
            Example("""
            let failure: Failure = { [↓weak self, ↓unowned delegate = self.delegate!] foo in
                print(foo)
            }
            """),
            Example("""
            numbers.forEach({
                [weak handler] in
                print($0)
            })
            """),
            Example("""
            numbers.forEach({
                [self, ↓weak handler] in
                print($0)
            })
            """),
            Example("""
            withEnvironment(apiService: MockService(fetchProjectResponse: project)) { [↓foo] in
                [Device.phone4_7inch, Device.phone5_8inch, Device.pad].forEach { device in
                    device.handle()
                }
            }
            """),
            Example("{ [↓foo] in _ }()"),
            Example("""
            let closure = { [↓weak a] in
                // The new `a` immediatly shadows the captured `a` which thus isn't needed.
                guard let a = getOptionalValue() else {
                    return
                }
                someInstanceFunction()
            }
            """)
        ]
    )
}

private extension UnusedCaptureListRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClosureExprSyntax) {
            guard let captureItems = node.signature?.capture?.items,
                  captureItems.isNotEmpty else {
                return
            }

            let captureItemsWithNames = captureItems
                .compactMap { item -> (name: String, item: ClosureCaptureSyntax)? in
                    if let name = item.name {
                        return (name.text, item)
                    } else if let expr = item.expression.as(DeclReferenceExprSyntax.self) {
                        // allow "[unowned self]"
                        if expr.baseName.tokenKind == .keyword(.self),
                           item.specifier?.specifier.tokenKind == .keyword(.unowned) {
                            return nil
                        }

                        // allow "[self]" capture (SE-0269)
                        if expr.baseName.tokenKind == .keyword(.self),
                           item.specifier == nil {
                            return nil
                        }

                        return (expr.baseName.text, item)
                    }

                    return nil
                }

            guard captureItemsWithNames.isNotEmpty else {
                return
            }

            let identifiersToSearch = Set(captureItemsWithNames.map(\.name))
            let foundIdentifiers = IdentifierReferenceVisitor(identifiersToSearch: identifiersToSearch)
                .walk(tree: node.statements, handler: \.foundIdentifiers)

            let missingIdentifiers = identifiersToSearch.subtracting(foundIdentifiers)
            guard missingIdentifiers.isNotEmpty else {
                return
            }

            for entry in captureItemsWithNames where missingIdentifiers.contains(entry.name) {
                violations.append(entry.item.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private final class IdentifierReferenceVisitor: SyntaxVisitor {
    private let identifiersToSearch: Set<String>
    private(set) var foundIdentifiers: Set<String> = []

    init(identifiersToSearch: Set<String>) {
        self.identifiersToSearch = identifiersToSearch
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: DeclReferenceExprSyntax) {
        collectReference(by: node.baseName)
    }

    override func visitPost(_ node: IdentifierPatternSyntax) {
        // Optional bindings without an initializer like `if let self { ... }` reference the captured `self`
        // implicitly. This is handled in here. If we have `if let self = self { ... }` the initializer `self`
        // is handled in the `IdentifierExprSyntax` case above.
        if let binding = node.parent?.as(OptionalBindingConditionSyntax.self), binding.initializer == nil {
            collectReference(by: node.identifier)
        }
    }

    private func collectReference(by token: TokenSyntax) {
        let name = token.text
        if identifiersToSearch.contains(name) {
            foundIdentifiers.insert(name)
        }
    }
}
