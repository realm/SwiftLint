import SwiftLintCore

struct OverriddenSuperCallConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = OverriddenSuperCallRule

    private let defaultIncluded = [
        // NSObject
        "awakeFromNib()",
        "prepareForInterfaceBuilder()",
        // UICollectionViewLayout
        "invalidateLayout()",
        "invalidateLayout(with:)",
        "invalidateLayoutWithContext(_:)",
        // UIView
        "prepareForReuse()",
        "updateConstraints()",
        // UIViewController
        "addChildViewController(_:)",
        "decodeRestorableState(with:)",
        "decodeRestorableStateWithCoder(_:)",
        "didReceiveMemoryWarning()",
        "encodeRestorableState(with:)",
        "encodeRestorableStateWithCoder(_:)",
        "removeFromParentViewController()",
        "setEditing(_:animated:)",
        "transition(from:to:duration:options:animations:completion:)",
        "transitionCoordinator()",
        "transitionFromViewController(_:toViewController:duration:options:animations:completion:)",
        "viewDidAppear(_:)",
        "viewDidDisappear(_:)",
        "viewDidLoad()",
        "viewWillAppear(_:)",
        "viewWillDisappear(_:)"
    ]

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = [String]()
    @ConfigurationElement(key: "included")
    private(set) var included = ["*"]

    private(set) var resolvedMethodNames: [String]

    init() {
        resolvedMethodNames = defaultIncluded
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let excluded = [String].array(of: configuration[$excluded]) {
            self.excluded = excluded
        }

        if let included = [String].array(of: configuration[$included]) {
            self.included = included
        }

        resolvedMethodNames = calculateResolvedMethodNames()
    }

    private func calculateResolvedMethodNames() -> [String] {
        var names: [String] = []
        if included.contains("*") && !excluded.contains("*") {
            names += defaultIncluded
        }
        names += included.filter({ $0 != "*" })
        names = names.filter { !excluded.contains($0) }
        return names
    }
}
