@testable import SwiftLintFramework
import XCTest

// swiftlint:disable function_body_length type_body_length
class TypeContentsOrderRuleTests: XCTestCase {
    func testTypeContentsOrderWithDefaultConfiguration() {
        // Test with default parameters
        #if swift(>=4.1)
        verifyRule(TypeContentsOrderRule.description)
        #else
        let compatibleDescription = TypeContentsOrderRule.description
            .with(triggeringExamples: compatibleExamples(from: TypeContentsOrderRuleExamples.triggeringExamples))

        verifyRule(compatibleDescription)
        #endif
    }

    func testTypeContentsOrderReversedOrder() {
        // Test with reversed `order` entries
        let nonTriggeringExamples = [
            [
                "class TestViewController: UIViewController {",
                TypeContentsOrderRuleExamples.defaultOrderParts.reversed().joined(separator: "\n\n"),
                "}"
            ].joined(separator: "\n")
        ]
        let triggeringExamples = [
            """
            class TestViewController: UIViewController {
                // Type Aliases
                ↓typealias CompletionHandler = ((TestEnum) -> Void)

                // Subtypes
                class TestClass {
                    // 10 lines
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Subtypes
                ↓class TestClass {
                    // 10 lines
                }

                // Stored Type Properties
                static let cellIdentifier: String = "AmazingCell"
            }
            """,
            """
            class TestViewController: UIViewController {
                // Stored Type Properties
                ↓static let cellIdentifier: String = "AmazingCell"

                // Stored Instance Properties
                var shouldLayoutView1: Bool!
            }
            """,
            """
            class TestViewController: UIViewController {
                // Computed Instance Properties
                private ↓var hasAnyLayoutedView: Bool {
                     return hasLayoutedView1 || hasLayoutedView2
                }

                // IBOutlets
                @IBOutlet private var view1: UIView!
            }
            """,
            """
            class TestViewController: UIViewController {
                // IBOutlets
                @IBOutlet private ↓var view1: UIView!

                // Initializers
                override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Type Methods
                ↓static func makeViewController() -> TestViewController {
                    // some code
                }

                // View Life-Cycle Methods
                override func viewDidLoad() {
                    super.viewDidLoad()

                    view1.setNeedsLayout()
                    view1.layoutIfNeeded()
                    hasLayoutedView1 = true
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // View Life-Cycle Methods
                override ↓func viewDidLoad() {
                    super.viewDidLoad()

                    view1.setNeedsLayout()
                    view1.layoutIfNeeded()
                    hasLayoutedView1 = true
                }

                // IBActions
                @IBAction func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // IBActions
                @IBAction ↓func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }

                // Other Methods
                func goToNextVc() { /* TODO */ }
            }
            """,
            """
            class TestViewController: UIViewController {
                // MARK: Other Methods
                ↓func goToNextVc() { /* TODO */ }

                // Subscripts
                subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
                    get {
                        return "This is just a test"
                    }

                    set {
                        log.warning("Just a test", newValue)
                    }
                }
            }
            """
        ]

        #if swift(>=4.1)
        let reversedOrderDescription = TypeContentsOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
        #else
        let reversedOrderDescription = TypeContentsOrderRule.description
            .with(triggeringExamples: compatibleExamples(from: triggeringExamples))
            .with(nonTriggeringExamples: nonTriggeringExamples)
        #endif

        verifyRule(
            reversedOrderDescription,
            ruleConfiguration: [
                "order": [
                    "subscript",
                    "other_method",
                    "ib_action",
                    "view_life_cycle_method",
                    "type_method",
                    "initializer",
                    "ib_outlet",
                    "ib_inspectable",
                    "instance_property",
                    "type_property",
                    "subtype",
                    ["type_alias", "associated_type"],
                    "case"
                ]
            ]
        )
    }

    func testTypeContentsOrderGroupedOrder() {
        // Test with grouped `order` entries
        let nonTriggeringExamples = [
            """
            class TestViewController: UIViewController {
                // Type Alias
                typealias CompletionHandler = ((TestClass) -> Void)

                // Subtype
                class TestClass {
                    // 10 lines
                }

                // Type Alias
                typealias CompletionHandler2 = ((TestStruct) -> Void)

                // Subtype
                struct TestStruct {
                    // 3 lines
                }

                // Type Alias
                typealias CompletionHandler3 = ((TestEnum) -> Void)

                // Subtype
                enum TestEnum {
                    // 5 lines
                }

                // Instance Property
                var shouldLayoutView1: Bool!

                // Type Property
                static let cellIdentifier: String = "AmazingCell"

                // Instance Property
                weak var delegate: TestViewControllerDelegate?

                // IBOutlet
                @IBOutlet private var view1: UIView!

                // Instance Property
                private var hasLayoutedView1: Bool = false

                // IBOutlet
                @IBOutlet private var view2: UIView!

                // Initializer
                override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                // Type Method
                static func makeViewController() -> TestViewController {
                    // some code
                }

                // Initializer
                required init?(coder aDecoder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }

                // View Life-Cycle Method
                override func viewDidLoad() {
                    super.viewDidLoad()

                    view1.setNeedsLayout()
                    view1.layoutIfNeeded()
                    hasLayoutedView1 = true
                }

                // Other Method
                func goToInfoVc() { /* TODO */ }

                // IBAction
                @IBAction func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }

                // Other Methods
                func goToNextVc() { /* TODO */ }

                // Subscript
                subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
                    get {
                        return "This is just a test"
                    }

                    set {
                        log.warning("Just a test", newValue)
                    }
                }

                // Other Method
                private func getRandomVc() -> UIViewController { return UIViewController() }

                /// View Life-Cycle Method
                override func viewDidLayoutSubviews() {
                    super.viewDidLayoutSubviews()

                    view2.setNeedsLayout()
                    view2.layoutIfNeeded()
                    hasLayoutedView2 = true
                }
            }
            """
        ]
        let triggeringExamples = [
            """
            class TestViewController: UIViewController {
                // Type Alias
                typealias CompletionHandler = ((TestClass) -> Void)

                // Instance Property
                ↓var shouldLayoutView1: Bool!

                // Subtype
                class TestClass {
                    // 10 lines
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Instance Property
                var shouldLayoutView1: Bool!

                // Initializer
                override ↓init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                // Type Property
                static let cellIdentifier: String = "AmazingCell"
            }
            """,
            """
            class TestViewController: UIViewController {
                // Initializer
                override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                // Other Method
                private ↓func getRandomVc() -> UIViewController { return UIViewController() }

                // Type Method
                static func makeViewController() -> TestViewController {
                    // some code
                }
            }
            """
        ]

        #if swift(>=4.1)
        let groupedOrderDescription = TypeContentsOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
        #else
        let groupedOrderDescription = TypeContentsOrderRule.description
            .with(triggeringExamples: compatibleExamples(from: triggeringExamples))
            .with(nonTriggeringExamples: nonTriggeringExamples)
        #endif

        verifyRule(
            groupedOrderDescription,
            ruleConfiguration: [
                "order": [
                    ["type_alias", "associated_type", "subtype"],
                    ["type_property", "instance_property", "ib_inspectable", "ib_outlet"],
                    ["initializer", "type_method"],
                    ["view_life_cycle_method", "ib_action", "other_method", "subscript"]
                ]
            ]
        )
    }

    #if swift(>=4.1)
    #else
    /// Removes examples including typealias and subscript since unsupported by SourceKit of Swift <4.1.
    private func compatibleExamples(from examples: [String]) -> [String] {
        return examples.filter { !$0.contains("typealias") && !$0.contains("subscript") }
    }
    #endif
}
