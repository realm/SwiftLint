import Foundation
import SourceKittenFramework

// swiftlint:disable:next type_body_length
public struct TypeContentsOrderRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    private typealias TypeContentOffset = (typeContent: TypeContent, offset: Int)

    public var configuration = TypeContentsOrderConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "type_contents_order",
        name: "Type Contents Order",
        description: "Specifies the order of subtypes, properties, methods & more within a type.",
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

                // Type Properties
                static let cellIdentifier: String = "AmazingCell"

                // Instance Properties
                var shouldLayoutView1: Bool!
                weak var delegate: TestViewControllerDelegate?
                private var hasLayoutedView1: Bool = false
                private var hasLayoutedView2: Bool = false

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

                // View Life-Cycle Methods
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

                // Other Methods
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
            class TestViewController: UIViewController {
                // Subtypes
                ↓class TestClass {
                    // 10 lines
                }

                // Type Aliases
                typealias CompletionHandler = ((TestEnum) -> Void)
            }
            """,
            """
            class TestViewController: UIViewController {
                // Stored Type Properties
                ↓static let cellIdentifier: String = "AmazingCell"

                // Subtypes
                class TestClass {
                    // 10 lines
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Stored Instance Properties
                ↓var shouldLayoutView1: Bool!

                // Stored Type Properties
                static let cellIdentifier: String = "AmazingCell"
            }
            """,
            """
            class TestViewController: UIViewController {
                // IBOutlets
                @IBOutlet private ↓var view1: UIView!

                // Computed Instance Properties
                private var hasAnyLayoutedView: Bool {
                     return hasLayoutedView1 || hasLayoutedView2
                }
            }
            """,
            """
            class TestViewController: UIViewController {
                // Initializers
                override ↓init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
                    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
                }

                // IBOutlets
                @IBOutlet private var view1: UIView!
                @IBOutlet private var view2: UIView!
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

                // Type Methods
                static func makeViewController() -> TestViewController {
                    // some code
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
                // Other Methods
                ↓func goToNextVc() { /* TODO */ }

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
                ↓subscript(_ someIndexThatIsNotEvenUsed: Int) -> String {
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

    public func validate(file: File) -> [StyleViolation] {
        let substructures = file.structure.dictionary.substructure
        return substructures.reduce([StyleViolation]()) { violations, substructure -> [StyleViolation] in
            return violations + validateTypeSubstructure(substructure, in: file)
        }
    }

    private func validateTypeSubstructure(
        _ substructure: [String: SourceKitRepresentable],
        in file: File
    ) -> [StyleViolation] {
        let typeContentOffsets = self.typeContentOffsets(in: substructure)
        let orderedTypeContentOffsets = typeContentOffsets.sorted { lhs, rhs in lhs.offset < rhs.offset }

        var violations =  [StyleViolation]()

        var lastMatchingIndex = -1
        for expectedTypesContents in configuration.order {
            var potentialViolatingIndexes = [Int]()

            let startIndex = lastMatchingIndex + 1
            (startIndex..<orderedTypeContentOffsets.count).forEach { index in
                let typeContent = orderedTypeContentOffsets[index].typeContent
                if expectedTypesContents.contains(typeContent) {
                    lastMatchingIndex = index
                } else {
                    potentialViolatingIndexes.append(index)
                }
            }

            let violatingIndexes = potentialViolatingIndexes.filter { $0 < lastMatchingIndex }
            violatingIndexes.forEach { index in
                let typeContentOffset = orderedTypeContentOffsets[index]

                let content = typeContentOffset.typeContent.rawValue
                let expectedContents = expectedTypesContents.map { $0.rawValue }.joined(separator: ",")
                let reason = "A '\(content)' should not be placed amongst the type content(s) '\(expectedContents)'."

                let styleViolation = StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, characterOffset: typeContentOffset.offset),
                    reason: reason
                )
                violations.append(styleViolation)
            }
        }

        return violations
    }

    private func typeContentOffsets(in typeStructure: [String: SourceKitRepresentable]) -> [TypeContentOffset] {
        return typeStructure.substructure.compactMap { typeContentStructure in
            guard let typeContent = self.typeContent(for: typeContentStructure) else { return nil }
            return (typeContent, typeContentStructure.offset!)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func typeContent(for typeContentStructure: [String: SourceKitRepresentable]) -> TypeContent? {
        guard let typeContentKind = SwiftDeclarationKind(rawValue: typeContentStructure.kind!) else { return nil }

        switch typeContentKind {
        case .enumcase, .enumelement:
            return .case

        case .typealias:
            return .typeAlias

        case .associatedtype:
            return .associatedType

        case .class, .enum, .extension, .protocol, .struct:
            return .subtype

        case .varClass, .varStatic:
            return .typeProperty

        case .varInstance:
            if typeContentStructure.enclosedSwiftAttributes.contains(SwiftDeclarationAttributeKind.iboutlet) {
                return .ibOutlet
            } else {
                return .instanceProperty
            }

        case .functionMethodClass, .functionMethodStatic:
            return .typeMethod

        case .functionMethodInstance:
            let viewLifecycleMethodNames = [
                "loadView(",
                "loadViewIfNeeded(",
                "viewDidLoad(",
                "viewWillAppear(",
                "viewWillLayoutSubviews(",
                "viewDidLayoutSubviews(",
                "viewDidAppear(",
                "viewWillDisappear(",
                "viewDidDisappear("
            ]

            if typeContentStructure.name!.starts(with: "init") || typeContentStructure.name!.starts(with: "deinit") {
                return .initializer
            } else if viewLifecycleMethodNames.contains(where: { typeContentStructure.name!.starts(with: $0) }) {
                return .viewLifeCycleMethod
            } else if typeContentStructure.enclosedSwiftAttributes.contains(SwiftDeclarationAttributeKind.ibaction) {
                return .ibAction
            } else {
                return .otherMethod
            }

        case .functionSubscript:
            return .subscript

        default:
            return nil
        }
    }
}
