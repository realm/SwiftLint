internal struct FileTypesOrderRuleExamples {
    static let defaultOrderParts = [
        """
        // Supporting Types
        protocol TestViewControllerDelegate {
            func didPressTrackedButton()
        }
        """,
        """
        // Main Type
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
            }

            override func viewDidLayoutSubviews() {
                super.viewDidLayoutSubviews()
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
        """,
        """
        // Extensions
        extension TestViewController: UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 1
            }
        }
        """
    ]

    static let nonTriggeringExamples = [
        Example(Self.defaultOrderParts.joined(separator: "\n\n")),
        Example("""
        // Only extensions
        extension Foo {}
        extension Bar {
        }
        """),
        Example("""
        // Main Type
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }

        // Preview Provider
        struct ContentView_Previews: PreviewProvider {
            static var previews: some View { ContentView() }
        }

        // Library Content Provider
        struct ContentView_LibraryContent: LibraryContentProvider {
            var views: [LibraryItem] {
                LibraryItem(ContentView())
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        ↓class TestViewController: UIViewController {}

        // Supporting Types
        protocol TestViewControllerDelegate {
            func didPressTrackedButton()
        }
        """),
        Example("""
        // Extensions
        ↓extension TestViewController: UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 1
            }
        }

        class TestViewController: UIViewController {}
        """),
        Example("""
        // Supporting Types
        protocol TestViewControllerDelegate {
            func didPressTrackedButton()
        }

        ↓class TestViewController: UIViewController {}

        // Supporting Types
        protocol TestViewControllerDelegate {
            func didPressTrackedButton()
        }
        """),
        Example("""
        // Supporting Types
        protocol TestViewControllerDelegate {
            func didPressTrackedButton()
        }

        // Extensions
        ↓extension TestViewController: UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 1
            }
        }

        class TestViewController: UIViewController {}

        // Extensions
        extension TestViewController: UITableViewDataSource {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return 1
            }
        }
        """),
        Example("""
        // Preview Provider
        ↓struct ContentView_Previews: PreviewProvider {
            static var previews: some View { ContentView() }
        }

        // Main Type
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        """),
        Example("""
        // Library Content Provider
        ↓struct ContentView_LibraryContent: LibraryContentProvider {
            var views: [LibraryItem] {
                LibraryItem(ContentView())
            }
        }

        // Main Type
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        """)
    ]
}
