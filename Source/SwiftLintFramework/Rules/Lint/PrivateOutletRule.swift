import SwiftSyntax

struct PrivateOutletRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = PrivateOutletRuleConfiguration(allowPrivateSet: false)

    init() {}

    static let description = RuleDescription(
        identifier: "private_outlet",
        name: "Private Outlets",
        description: "IBOutlets should be private to avoid leaking UIKit to higher layers.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("class Foo {\n  @IBOutlet private var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private var label: UILabel!\n}\n"),
            Example("class Foo {\n  var notAnOutlet: UILabel\n}\n"),
            Example("class Foo {\n  @IBOutlet weak private var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private weak var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet fileprivate weak var label: UILabel?\n}\n"),
            // allow_private_set
            Example(
                "class Foo {\n  @IBOutlet private(set) var label: UILabel?\n}\n",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo {\n  @IBOutlet private(set) var label: UILabel!\n}\n",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo {\n  @IBOutlet weak private(set) var label: UILabel?\n}\n",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo {\n  @IBOutlet private(set) weak var label: UILabel?\n}\n",
                configuration: ["allow_private_set": true]
            ),
            Example(
                "class Foo {\n  @IBOutlet fileprivate(set) weak var label: UILabel?\n}\n",
                configuration: ["allow_private_set": true]
            )
        ],
        triggeringExamples: [
            Example("class Foo {\n  @IBOutlet ↓var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet ↓var label: UILabel!\n}\n"),
            Example("class Foo {\n  @IBOutlet private(set) ↓var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet fileprivate(set) ↓var label: UILabel?\n}\n"),
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
                decl.attributes?.hasIBOutlet == true,
                decl.modifiers?.isPrivateOrFilePrivate != true
            else {
                return
            }

            if allowPrivateSet && decl.modifiers?.isPrivateOrFilePrivateSet == true {
                return
            }

            violations.append(decl.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension AttributeListSyntax {
    var hasIBOutlet: Bool {
        contains { $0.as(AttributeSyntax.self)?.attributeName.text == "IBOutlet" }
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
