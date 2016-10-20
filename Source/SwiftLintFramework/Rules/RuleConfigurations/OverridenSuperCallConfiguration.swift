//
//  OverridenSuperCallConfiguration.swift
//  SwiftLint
//
//  Created by Angel Garcia on 05/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct OverridenSuperCallConfiguration: RuleConfiguration, Equatable {
    var defaultIncluded = [
        //NSObject
        "awakeFromNib()",
        "prepareForInterfaceBuilder()",
        //UICollectionViewLayout
        "invalidateLayout()",
        "invalidateLayout(with:)",
        "invalidateLayoutWithContext(_:)",
        //UIView
        "prepareForReuse()",
        "updateConstraints()",
        //UIViewController
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
        "viewWillDisappear(_:)",
        //XCTestCase
        "setUp()",
        "tearDown()"
    ]

    var severityConfiguration = SeverityConfiguration(.Warning)
    var excluded: [String] = []
    var included: [String] = ["*"]

    public private(set) var resolvedMethodNames: [String]

    init() {
        resolvedMethodNames = defaultIncluded
    }

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", excluded: [\(excluded)]" +
            ", included: [\(included)]"
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }

        if let excluded = [String].arrayOf(configuration["excluded"]) {
            self.excluded = excluded
        }

        if let included = [String].arrayOf(configuration["included"]) {
            self.included = included
        }

        self.resolvedMethodNames = calculateResolvedMethodNames()
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
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

public func == (lhs: OverridenSuperCallConfiguration,
                rhs: OverridenSuperCallConfiguration) -> Bool {
    return lhs.excluded == rhs.excluded &&
        lhs.included == rhs.included &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
