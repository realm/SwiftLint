import Foundation
import SwiftLintCore

struct CommentStyleConfiguration: RuleConfiguration, Equatable {
	typealias Parent = CommentStyleRule

	/// Set this value to enforce a comment style for the entire project. If unset, each file will be evaluated
	/// individually and enforce consistency with whatever style appears first within the file.
	@ConfigurationElement(key: "comment_style")
	private(set) var commentStyle: Style?
	/// The number of single line comments allowed before requiring a multiline comment.
	/// Only valid when `comment_style` is set to `mixed`
	@ConfigurationElement(key: "line_comment_threshold")
	private(set) var lineCommentThreshold: Int?
	@ConfigurationElement(key: "severity")
	private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

	mutating func apply(configuration: Any) throws {
		guard
			let configurationDict = configuration as? [String: Any]
		else { throw Issue.unknownConfiguration(ruleID: Parent.identifier) }

		if let commentStyleString: String = configurationDict[key: $commentStyle] {
			let style = Style(rawValue: commentStyleString)
			style != nil ? () : print("'\(commentStyleString)' invalid for comment style. No style enforce.")
			self.commentStyle = style
		}

		if
			commentStyle == .mixed,
			let lineCommentThreshold: Int = configurationDict[key: $lineCommentThreshold] {
			self.lineCommentThreshold = lineCommentThreshold
		}

		if let severityString: String = configurationDict[key: $severityConfiguration] {
			try severityConfiguration.apply(configuration: severityString)
		}
	}
}

extension CommentStyleConfiguration {
	enum Style: String, AcceptableByConfigurationElement {
		case multiline
		case singleline
		case mixed

		func asOption() -> SwiftLintCore.OptionType { .string(rawValue) }
	}
}

extension Dictionary where Key == String, Value == Any {
	subscript<T>(key key: String) -> T? {
		self[key] as? T
	}
}
