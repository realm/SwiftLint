import Foundation

struct CommentStyleRuleExamples {
	static func generateNonTriggeringExamples() -> [Example] {
		passingExamples.flatMap { wrapExample($0, shouldBePassing: true) }
	}

	static let passingExamples = [
		Example(
			"""
			// This is a comment
			"""),
		Example(
			"""
			/* This is a comment */
			"""),
		Example(
			"""
			// This is
			// three lines
			// of comments
			"""),
		Example(
			"""
			// This is
			// three lines
			// of comments

			// which then get separated by a single line
			// before more comments
			"""),
		Example(
			"""
			// This is
			// three lines
			// of comments


			// which then get separated by two lines
			// before more comments
			"""),
		Example(
			"""
			/* This is a
			three line
			comment */
			"""),
		Example(
			"""
			/*
			This is a
			multiline
			comment
			*/
			"""),
		Example(
			"""
			/*
			This is a
			multiline
			comment
			*/

			// This is
			// three lines
			// of comments
			""",
			configuration: ["comment_style": "mixed"],
			excludeFromDocumentation: true),
	]


	private static func wrapExample(_ example: Example, shouldBePassing: Bool) -> [Example] {
		let naked = example.with(code: """
			\(example.code)
			""")
		let inClass = example.with(code: """
			class Foo {
			\(example.code.appendIndentation(level: 1))
			}
			""")
		let inFunction = example.with(code: """
			class Foo {
				func bar() {
			\(example.code.appendIndentation(level: 2))
				}
			}
			""")
		let inClosure = example.with(code: """
			class Foo {
				let bar = {
			\(example.code.appendIndentation(level: 2))
				}
			}
			""")
		let inString = example.with(code: """
			class Bar {
				let mahString = \"""
					// A Comment!
					// But not really
					/*
					It's actually a string!
					tricksies and should not get triggered
					*/
			\(example.code.appendIndentation(level: 2))
					\"""
			}
			""")
		let inAll = example.with(code: """
			class FooBar {
			\(example.code.appendIndentation(level: 1))
				let bar = {
			\(example.code.appendIndentation(level: 2))
				}

				func bar() {
			\(example.code.appendIndentation(level: 2))
				}
			}
			""")
		return shouldBePassing ?
		[naked, inClass, inFunction, inClosure, inString, inAll] :
		[naked, inClass, inFunction, inClosure, inAll]

	}
}

private extension String {
	func appendIndentation(level: Int) -> String {
		let tabs = Array(repeating: "\t", count: level)
			.joined()

		return split(separator: "\n", omittingEmptySubsequences: false)
			.map { "\(tabs)\(String($0))\n" }
			.joined()
	}
}
