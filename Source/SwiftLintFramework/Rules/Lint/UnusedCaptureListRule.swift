import SwiftSyntax

struct UnusedCaptureListRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "unused_capture_list",
        name: "Unused Capture List",
        description: "Unused reference in a capture list should be removed.",
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
            Example("{ [↓foo] in _ }()")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UnusedCaptureListRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ClosureExprSyntax) {
            guard let captureItems = node.signature?.capture?.items,
                    captureItems.isNotEmpty else {
                return
            }

            let captureItemsWithNames = captureItems
                .compactMap { item -> (name: String, item: ClosureCaptureItemSyntax)? in
                    if let name = item.name {
                        return (name.text, item)
                    } else if let expr = item.expression.as(IdentifierExprSyntax.self) {
                        // allow "[unowned self]"
                        if expr.identifier.tokenKind == .selfKeyword && item.specifier.containsUnowned {
                            return nil
                        }

                        // allow "[self]" capture (SE-0269)
                        if expr.identifier.tokenKind == .selfKeyword && item.specifier.isNilOrEmpty {
                            return nil
                        }

                        return (expr.identifier.text, item)
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
                violations.append(
                    ReasonedRuleViolation(
                        position: entry.item.positionAfterSkippingLeadingTrivia,
                        reason: "Unused reference \(entry.name) in a capture list should be removed."
                    )
                )
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

    override func visitPost(_ node: IdentifierExprSyntax) {
        let name = node.identifier.text
        if identifiersToSearch.contains(name) {
            foundIdentifiers.insert(name)
        }
    }
}

private extension TokenListSyntax? {
    var containsUnowned: Bool {
        self?.contains { token in
            token.tokenKind == .contextualKeyword("unowned")
        } ?? false
    }

    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
