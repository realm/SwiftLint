import Foundation

struct CommentStyleRuleExamples {
	static func generateNonTriggeringExamples() -> [Example] {
		passingExamples.flatMap { wrapExample($0, shouldBePassing: true) }
	}

	static func generateTriggeringExamples() -> [Example] {
		failingExamples.flatMap { wrapExample($0, shouldBePassing: false) }
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
			// some single lines
			// of comments
			// and `comment_style` is set to `mixed
			""",
			configuration: ["comment_style": "mixed"]),
		Example(
			"""
			// This is
			// five lines
			// of comments,
			// with the mode set to "mixed"
			// and `line_comment_threshold` for multiline set to 6
			""",
			configuration: [
				"comment_style": "mixed",
				"line_comment_threshold": 6,
			]),
		Example(
			"""
			/*
			This is
			a long
			multiline comment,
			with `comment_style` set to "mixed"
			and `line_comment_threshold`
			for multiline set to 4
			*/

			// and three lines
			// of single line
			// comments
			""",
			configuration: [
				"comment_style": "mixed",
				"line_comment_threshold": 4,
			]),
	]

	static let failingExamples = [
		Example(
			"""
			// This is a comment
			↓/* This is a comment */
			"""),
		Example(
			"""
			/* This is a comment */
			↓// This is a comment
			"""),
		Example(
			"""
			↓// This is a comment with config set to multiline
			""",
			configuration: ["comment_style": "multiline"]),
		Example(
			"""
			↓/* This is a comment with config set to singleline */
			""",
			configuration: ["comment_style": "singleline"]),
		Example(
			"""
			↓/* This is a comment with config set to singleline */
			// This is a comment
			""",
			configuration: ["comment_style": "singleline"]),
		Example(
			"""
			↓// This is a comment with config set to multiline
			/* This is a comment */
			""",
			configuration: ["comment_style": "multiline"]),
		Example(
			"""
			↓// This is
			// five lines
			// of comments,
			// with the mode set to "mixed"
			// and `line_comment_threshold` for multiline set to 5
			""",
			configuration: [
				"comment_style": "mixed",
				"line_comment_threshold": 5,
			]),
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

		let inString: Example?
		if shouldBePassing {
			inString = example.with(code: """
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
		} else {
			inString = nil
		}

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

		let firstCommentStyle = {
			guard
				let index = example.code.firstIndex(of: "/")
			else { return CommentStyleRule.ConfigurationType.Style.mixed }

			let characterAfter = example.code[example.code.index(after: index)]
			switch characterAfter {
			case "/":
				return .singleline
			case "*":
				return .multiline
			default: return .mixed
			}
		}()
		let offsetString = {
			let multiBytes = ""
			switch firstCommentStyle {
			case .singleline:
				return "// \(multiBytes)\n"
			default:
				return "/*\n\(multiBytes)\n*/"
			}
		}()
		let multiByteOffset = example.with(code: """
			\(offsetString)
			\(example.code)
			""")

		return [
			naked,
			inClass,
			inFunction,
			inClosure,
			inString,
			inAll,
			multiByteOffset
		].compactMap { $0 }

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
