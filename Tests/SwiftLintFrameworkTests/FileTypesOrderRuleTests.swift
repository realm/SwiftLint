@testable import SwiftLintFramework
import XCTest

// swiftlint:disable function_body_length

class FileTypesOrderRuleTests: XCTestCase {
    func testFileTypesOrderWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(FileTypesOrderRule.description)
    }

    func testFileTypesOrderReversedOrder() {
        // Test with reversed `order` entries
        let nonTriggeringExamples = [
            Example(FileTypesOrderRuleExamples.defaultOrderParts.reversed().joined(separator: "\n\n"))
        ]
        let triggeringExamples = [
            Example("""
            // Supporting Types
            ↓protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }

            class TestViewController: UIViewController {}
            """),
            Example("""
            ↓class TestViewController: UIViewController {}

            // Extensions
            extension TestViewController: UITableViewDataSource {
                func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                    return 1
                }

                func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    return UITableViewCell()
                }
            }
            """),
            Example("""
            // Supporting Types
            ↓protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }

            class TestViewController: UIViewController {}

            // Supporting Types
            protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }
            """),
            Example("""
            ↓struct ContentView: View {
               var body: some View {
                   Text("Hello, World!")
               }
            }

            struct ContentView_Previews: PreviewProvider {
               static var previews: some View { ContentView() }
            }
            """)
        ]

        let reversedOrderDescription = FileTypesOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            reversedOrderDescription,
            ruleConfiguration: [
                "order": ["preview_provider", "extension", "main_type", "supporting_type"]
            ]
        )
    }

    func testFileTypesOrderGroupedOrder() {
        // Test with grouped `order` entries
        let nonTriggeringExamples = [
            Example("""
            class TestViewController: UIViewController {}

            // Supporting Type
            protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }

            // Extension
            extension TestViewController: UITableViewDataSource {
                func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                    return 1
                }
            }

            // Supporting Type
            protocol TestViewControllerDelegate2 {
                func didPressTrackedButton()
            }

            // Extension
            extension TestViewController: UITableViewDelegate {
                func someMethod() {}
            }
            """)
        ]
        let triggeringExamples = [
            Example("""
            // Supporting Types
            ↓protocol TestViewControllerDelegate {
                func didPressTrackedButton()
            }

            class TestViewController: UIViewController {}
            """),
            Example("""
            // Extensions
            ↓extension TestViewController: UITableViewDataSource {
                func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                    return 1
                }

                func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    return UITableViewCell()
                }
            }

            class TestViewController: UIViewController {}
            """)
        ]

        let groupedOrderDescription = FileTypesOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            groupedOrderDescription,
            ruleConfiguration: [
                "order": ["main_type", ["extension", "supporting_type"], "preview_provider"]
            ]
        )
    }
}
