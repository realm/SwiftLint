import SwiftSyntax

struct PrivateOutletRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = PrivateOutletConfiguration()

    static let description = RuleDescription(
        identifier: "private_outlet",
        name: "Private Outlets",
        description: "IBOutlets should be private to avoid leaking UIKit to higher layers",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo { @IBOutlet private var label: UILabel? }"),
            Example("class Foo { @IBOutlet private var label: UILabel! }"),
            Example("class Foo { var notAnOutlet: UILabel }"),
            Example("class Foo { @IBOutlet weak private var label: UILabel? }"),
            Example("class Foo { @IBOutlet private weak var label: UILabel? }"),
            Example("class Foo { @IBOutlet fileprivate weak var label: UILabel? }"),
            // allow_private_set
            Example(
                "class Foo { @IBOutlet private(set) var label: UILabel? }",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo { @IBOutlet private(set) var label: UILabel! }",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo { @IBOutlet weak private(set) var label: UILabel? }",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo { @IBOutlet private(set) weak var label: UILabel? }",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo { @IBOutlet fileprivate(set) weak var label: UILabel? }",
                configuration: ["allow_private_set": true]
            )
        ],
        triggeringExamples: [
            Example("class Foo { @IBOutlet ↓var label: UILabel? }"),
            Example("class Foo { @IBOutlet ↓var label: UILabel! }"),
            Example("class Foo { @IBOutlet private(set) ↓var label: UILabel? }"),
            Example("class Foo { @IBOutlet fileprivate(set) ↓var label: UILabel? }"),
            Example("""
            import Gridicons

            class BlogDetailsSectionHeaderView: UITableViewHeaderFooterView {
                typealias EllipsisCallback = (BlogDetailsSectionHeaderView) -> Void
                @IBOutlet private var titleLabel: UILabel?

                @objc @IBOutlet private(set) ↓var ellipsisButton: UIButton? {
                    didSet {
                        ellipsisButton?.setImage(UIImage.gridicon(.ellipsis), for: .normal)
                    }
                }

                @objc var title: String = "" {
                    didSet {
                        titleLabel?.text = title.uppercased()
                    }
                }

                @objc var ellipsisButtonDidTouch: EllipsisCallback?

                override func awakeFromNib() {
                    super.awakeFromNib()
                    titleLabel?.textColor = .textSubtle
                }

                @IBAction func ellipsisTapped() {
                    ellipsisButtonDidTouch?(self)
                }
            }
            """, configuration: ["allow_private_set": false], excludeFromDocumentation: true)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(allowPrivateSet: configuration.allowPrivateSet)
    }
}

private extension PrivateOutletRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allowPrivateSet: Bool

        init(allowPrivateSet: Bool) {
            self.allowPrivateSet = allowPrivateSet
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: MemberDeclListItemSyntax) {
            guard
                let decl = node.decl.as(VariableDeclSyntax.self),
                decl.attributes.contains(attributeNamed: "IBOutlet"),
                decl.modifiers?.isPrivateOrFilePrivate != true
            else {
                return
            }

            if allowPrivateSet && decl.modifiers?.isPrivateOrFilePrivateSet == true {
                return
            }

            violations.append(decl.bindingKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ModifierListSyntax {
    var isPrivateOrFilePrivate: Bool {
        contains(where: \.isPrivateOrFilePrivate)
    }

    var isPrivateOrFilePrivateSet: Bool {
        contains(where: \.isPrivateOrFilePrivateSet)
    }
}

private extension ModifierListSyntax.Element {
    var isPrivateOrFilePrivate: Bool {
        (name.text == "private" || name.text == "fileprivate") && detail == nil
    }

    var isPrivateOrFilePrivateSet: Bool {
        (name.text == "private" || name.text == "fileprivate") && detail?.detail.text == "set"
    }
}
