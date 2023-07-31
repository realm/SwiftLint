import Foundation

struct CommentStyleRuleExamples {
	static func generateNonTriggeringExamples() -> [Example] {
		passingExamples.flatMap { wrapExample($0) }
	}

	static func generateTriggeringExamples() -> [Example] {
		failingExamples.flatMap { wrapExample($0) }
	}

	private static let passingExamples = [
		ExampleInfo(
			"""
			// This is a comment
			""",
			multibyteMode: .singleline,
			isTriggering: false),
		ExampleInfo(
			"""
			/* This is a comment */
			""",
			multibyteMode: .multiline,
			isTriggering: false),
		ExampleInfo(
			"""
			// This is
			// three lines
			// of comments
			""",
			multibyteMode: .singleline,
			isTriggering: false),
		ExampleInfo(
			"""
			// This is
			// three lines
			// of comments

			// which then get separated by a single line
			// before more comments
			""",
			multibyteMode: .singleline,
			isTriggering: false),
		ExampleInfo(
			"""
			// This is
			// three lines
			// of comments


			// which then get separated by two lines
			// before more comments
			""",
			multibyteMode: .singleline,
			isTriggering: false),
		ExampleInfo(
			"""
			/* This is a
			three line
			comment */
			""",
			isTriggering: false),
		ExampleInfo(
			"""
			/*
			This is a
			multiline
			comment
			*/
			""",
			isTriggering: false),
		ExampleInfo(
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
			configuration: ["comment_style": "mixed"],
			isTriggering: false),
		ExampleInfo(
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
			],
			isTriggering: false),
		ExampleInfo(
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
			],
			isTriggering: false),
	]

	private static let failingExamples = [
		ExampleInfo(
			"""
			// This is a comment
			↓/* This is a comment */
			""",
			multibyteMode: .singleline,
			isTriggering: true),
		ExampleInfo(
			"""
			/* This is a comment */
			↓// This is a comment
			""",
			multibyteMode: .multiline,
			isTriggering: true),
		ExampleInfo(
			"""
			↓// This is a comment with config set to multiline
			""",
			configuration: ["comment_style": "multiline"],
			multibyteMode: .multiline,
			isTriggering: true),
		ExampleInfo(
			"""
			↓/* This is a comment with config set to singleline */
			""",
			configuration: ["comment_style": "singleline"],
			multibyteMode: .singleline,
			isTriggering: true),
		ExampleInfo(
			"""
			↓/* This is a comment with config set to singleline */
			// This is a comment
			""",
			configuration: ["comment_style": "singleline"],
			multibyteMode: .singleline,
			isTriggering: true),
		ExampleInfo(
			"""
			↓// This is a comment with config set to multiline
			/* This is a comment */
			""",
			configuration: ["comment_style": "multiline"],
			isTriggering: true),
		ExampleInfo(
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
			],
			isTriggering: true),
	]

	private static func wrapExample(_ exampleInfo: ExampleInfo) -> [Example] {
		let naked = exampleInfo.example.with(code: """
			\(exampleInfo.example.code)
			""")
		let inClass = exampleInfo.example.with(code: """
			class Foo {
			\(exampleInfo.example.code.appendIndentation(level: 1))
			}
			""")
		let inFunction = exampleInfo.example.with(code: """
			class Foo {
				func bar() {
			\(exampleInfo.example.code.appendIndentation(level: 2))
				}
			}
			""")

		let inClosure = exampleInfo.example.with(code: """
			class Foo {
				let bar = {
			\(exampleInfo.example.code.appendIndentation(level: 2))
				}
			}
			""")

		let inString: Example?
		if exampleInfo.isTriggering == false {
			inString = exampleInfo.example.with(code: """
				class Bar {
					let mahString = \"""
						// A Comment!
						// But not really
						/*
						It's actually a string!
						tricksies and should not get triggered
						*/
				\(exampleInfo.example.code.appendIndentation(level: 2))
						\"""
				}
				""")
		} else {
			inString = nil
		}

		let inAll = exampleInfo.example.with(code: """
			class FooBar {
			\(exampleInfo.example.code.appendIndentation(level: 1))
				let bar = {
			\(exampleInfo.example.code.appendIndentation(level: 2))
				}

				func bar() {
			\(exampleInfo.example.code.appendIndentation(level: 2))
				}
			}
			""")

		let offsetString = {
			let multiBytes = " 👨‍👩‍👧‍👦👨‍👩‍👧‍👦👨‍👩‍👧‍👦 "
			switch exampleInfo.multibyteMode {
			case .singleline:
				return "// \(multiBytes)\n"
			default:
				return "/*\n\(multiBytes)\n*/"
			}
		}()
		let multiByteOffset = exampleInfo.example.with(code: """
			\(offsetString)
			\(exampleInfo.example.code)
			""")

		// disable comment wrapping and multibyte tests because they are already done within this file
		return [
			naked,
			inClass,
			inFunction,
			inClosure,
			inString,
			inAll,
			multiByteOffset
		].compactMap { $0 }
			.skipWrappingInCommentTests()
			.skipMultiByteOffsetTests()
	}

	private struct ExampleInfo {
		typealias Style = CommentStyleRule.ConfigurationType.Style
		let example: Example
		let multibyteMode: Style?
		let isTriggering: Bool

		init(
			_ code: String,
			configuration: [String: Any]? = nil,
			multibyteMode: Style? = nil,
			isTriggering: Bool,
			file: StaticString = #file,
			line: UInt = #line) {
				self.init(
					example: Example(code, configuration: configuration, file: file, line: line),
					multibyteMode: multibyteMode,
					isTriggering: isTriggering)
			}

		init(example: Example, multibyteMode: Style? = nil, isTriggering: Bool) {
			self.example = example
			self.multibyteMode = multibyteMode
			self.isTriggering = isTriggering
		}

		func editExample(_ block: (Example) -> Example) -> ExampleInfo {
			let newExample = block(example)
			return ExampleInfo(example: newExample, multibyteMode: multibyteMode, isTriggering: isTriggering)
		}

		func focused() -> ExampleInfo {
			editExample { $0.focused() }
		}
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
