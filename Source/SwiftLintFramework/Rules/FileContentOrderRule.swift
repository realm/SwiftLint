import Foundation
import SourceKittenFramework

// swiftlint:disable:next type_body_length
public struct FileContentOrderRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_content_order",
        name: "File Content Order",
        description: "Specifies the order of types, properties, methods & more within a file including one main type.",
        kind: .style,
        nonTriggeringExamples: [
            """
            // Supporting Types
            protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }

            class TestViewController: UIViewController {
                // Type Aliases
                typealias CompletionHandler = ((TestEnum) -> Void)

                // Subtypes
                class TestClass {
                    // 10 lines
                }

                struct TestStruct {
                    // 3 lines
                }

                enum TestEnum {
                    // 5 lines
                }

                // Stored Type Properties
                static let cellIdentifier: String = "AmazingCell"

                // Stored Instance Properties
                var shouldLayoutView1: Bool!
                weak var delegate: TestViewControllerDelegate?
                private var hasLayoutedView1: Bool = false
                private var hasLayoutedView2: Bool = false

                // Computed Instance Properties
                private var hasAnyLayoutedView: Bool {
                     return hasLayoutedView1 || hasLayoutedView2
                }

                // IBOutlets
                @IBOutlet private var view1: UIView!
                @IBOutlet private var view2: UIView!

                // Initializers
                override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                required init?(coder aDecoder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }

                // Type Methods
                static func makeViewController() -> TestViewController {
                    // some code
                }

                // Life-Cycle Methods
                override func viewDidLoad() {
                    super.viewDidLoad()

                    view1.setNeedsLayout()
                    view1.layoutIfNeeded()
                    hasLayoutedView1 = true
                }

                override func viewDidLayoutSubviews() {
                    super.viewDidLayoutSubviews()

                    view2.setNeedsLayout()
                    view2.layoutIfNeeded()
                    hasLayoutedView2 = true
                }

                // IBActions
                @IBAction func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }

                @objc
                func goToRandomVcButtonPressed() {
                    goToRandomVc()
                }

                // MARK: Other Methods
                func goToNextVc() { /* TODO */ }

                func goToInfoVc() { /* TODO */ }

                func goToRandomVc() {
                    let viewCtrl = getRandomVc()
                    present(viewCtrl, animated: true)
                }

                private func getRandomVc() -> UIViewController { return UIViewController() }

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

            // Extensions
            extension TestViewController: UITableViewDataSource {
                func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                    return 1
                }

                func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    return UITableViewCell()
                }
            }
            """
        ],
        triggeringExamples: [
            """
            class TestViewController: UIViewController {}

            // Supporting Types
            protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }
            """,
            """
            // Extensions
            extension TestViewController: UITableViewDataSource {
                func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                    return 1
                }

                func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    return UITableViewCell()
                }
            }

            class TestViewController: UIViewController {}
            """,
            """
            class TestViewController: UIViewController {
                // Subtypes
                class TestClass {
                    // 10 lines
                }

                // Type Aliases
                typealias CompletionHandler = ((TestEnum) -> Void)
            }
            """,
            """
            class TestViewController: UIViewController {
                // Stored Type Properties
                static let cellIdentifier: String = "AmazingCell"

                // Subtypes
                class TestClass {
                    // 10 lines
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Stored Instance Properties
                var shouldLayoutView1: Bool!
                weak var delegate: TestViewControllerDelegate?
                private var hasLayoutedView1: Bool = false
                private var hasLayoutedView2: Bool = false

                // Stored Type Properties
                static let cellIdentifier: String = "AmazingCell"
            }
            """,
            """
            class TestViewController: UIViewController {
                // Computed Instance Properties
                private var hasAnyLayoutedView: Bool {
                     return hasLayoutedView1 || hasLayoutedView2
                }

                // Stored Instance Properties
                var shouldLayoutView1: Bool!
                weak var delegate: TestViewControllerDelegate?
                private var hasLayoutedView1: Bool = false
                private var hasLayoutedView2: Bool = false
            }
            """,
            """
            class TestViewController: UIViewController {
                // IBOutlets
                @IBOutlet private var view1: UIView!
                @IBOutlet private var view2: UIView!

                // Computed Instance Properties
                private var hasAnyLayoutedView: Bool {
                     return hasLayoutedView1 || hasLayoutedView2
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Initializers
                override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                // IBOutlets
                @IBOutlet private var view1: UIView!
                @IBOutlet private var view2: UIView!
            }
            """,
            """
            class TestViewController: UIViewController {
                // Life-Cycle Methods
                override func viewDidLoad() {
                    super.viewDidLoad()

                    view1.setNeedsLayout()
                    view1.layoutIfNeeded()
                    hasLayoutedView1 = true
                }

                // Type Methods
                static func makeViewController() -> TestViewController {
                    // some code
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // IBActions
                @IBAction func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }

                // Life-Cycle Methods
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
                // MARK: Other Methods
                func goToNextVc() { /* TODO */ }

                // IBActions
                @IBAction func goNextButtonPressed() {
                    goToNextVc()
                    delegate?.didPressTrackedButton()
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Subscripts
                subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
                    get {
                        return "This is just a test"
                    }

                    set {
                        log.warning("Just a test", newValue)
                    }
                }

                // MARK: Other Methods
                func goToNextVc() { /* TODO */ }
            }
            """
        ]
    )

    public func validate(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {
        return [] // TODO: not yet implemented
    }
}

//private extension File {
//    func violatingRanges(for pattern: String) -> [NSRange] {
//        return match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
//    }
//}

//private extension Dictionary where Key: StringProtocol, Value: StringProtocol {
//    func cleanedKeysDict() -> [String: String] {
//        var cleanDict = [String: String]()
//
//        for (key, value) in self {
//            guard let keyString = key as? String else { continue }
//            let cleanedKey = keyString.replacingOccurrences(of: "↓", with: "")
//            cleanDict[cleanedKey] = value as? String
//        }
//
//        return cleanDict
//    }
//}
