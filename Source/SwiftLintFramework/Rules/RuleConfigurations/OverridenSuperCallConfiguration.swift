//
//  OverridenSuperCallConfiguration.swift
//  SwiftLint
//
//  Created by Angel Garcia on 05/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct OverridenSuperCallConfiguration: RuleConfiguration, Equatable {
    private let defaultIncluded = [
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

    public let parameters: [ParameterDefinition]
    private var severityParameter = SeverityConfiguration(.warning).severityParameter
    private var excludedParameter: ArrayParameter<String>
    private var includedParameter: ArrayParameter<String>

    public private(set) var resolvedMethodNames: [String]

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var excluded: [String] {
        return excludedParameter.value
    }

    var included: [String] {
        return includedParameter.value
    }

    public init(excluded: [String] = [], included: [String] = ["*"]) {
        excludedParameter = ArrayParameter(key: "excluded",
                                           default: excluded,
                                           description: "How serious")
        includedParameter = ArrayParameter(key: "apply_to_dictionaries",
                                           default: included,
                                           description: "How serious")
        parameters = [excludedParameter, includedParameter, severityParameter]
        resolvedMethodNames = defaultIncluded
        resolvedMethodNames = calculateResolvedMethodNames()
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try severityParameter.parse(from: configuration)
        try excludedParameter.parse(from: configuration)
        try includedParameter.parse(from: configuration)

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

    public static func == (lhs: OverridenSuperCallConfiguration,
                    rhs: OverridenSuperCallConfiguration) -> Bool {
        return lhs.excluded == rhs.excluded &&
            lhs.included == rhs.included &&
            lhs.severity == rhs.severity
    }

}
