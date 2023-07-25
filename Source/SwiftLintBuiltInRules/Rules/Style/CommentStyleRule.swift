import Foundation
import SwiftSyntax
import SwiftIDEUtils

struct CommentStyleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
	typealias ConfigurationType = CommentStyleConfiguration
	var configuration = ConfigurationType()

	static let description = RuleDescription(
		identifier: "comment_style",
		name: "Comment Style",
		description: """
			Allows for options to enforce styling of comments. Should all comments be multiline comments? Should they be single
			line? Or should there be a threshhold, where if x number of single line comments are in a row, should they be
			multiline?
			""",
		kind: .style,
		minSwiftVersion: .current,
		nonTriggeringExamples: CommentStyleRuleExamples.generateNonTriggeringExamples(),
		triggeringExamples: CommentStyleRuleExamples.generateTriggeringExamples())

	func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
		Visitor(configuration: configuration, file: file)
	}
}

extension CommentStyleRule {
	class Visitor: ViolationsSyntaxVisitor {
		typealias Parent = CommentStyleRule
		private let allCommentGroupings: [CommentGrouping]
		let file: SwiftLintFile

		let configuration: Parent.ConfigurationType

		typealias Style = Parent.ConfigurationType.Style
		private var commentStyle: Style?

		enum CommentGrouping {
			case singleline([SyntaxClassifiedRange])
			case multiline([SyntaxClassifiedRange])
			case singlelineDoc([SyntaxClassifiedRange])
			case multilineDoc([SyntaxClassifiedRange])
		}

		init(configuration: Parent.ConfigurationType, file: SwiftLintFile) {
			self.configuration = configuration
			self.file = file

			var rangeGroupings: [CommentGrouping] = []
			var commentsAccumulator: [SyntaxClassifiedRange] = []

			func appendCommentsAccumulator() {
				guard commentsAccumulator.isEmpty == false else { return }

				guard
					let kind = commentsAccumulator.first?.kind,
					commentsAccumulator.allSatisfy({ $0.kind == kind })
				else { queuedFatalError("Accumulator acquired mixed comment kind...") }

				switch kind {
				case .lineComment:
					rangeGroupings.append(.singleline(commentsAccumulator))
				case .blockComment:
					rangeGroupings.append(.multiline(commentsAccumulator))
				case .docLineComment:
					rangeGroupings.append(.singlelineDoc(commentsAccumulator))
				case .docBlockComment:
					rangeGroupings.append(.multilineDoc(commentsAccumulator))
				default:
					queuedFatalError("non comment in comment accumulator")
				}
				commentsAccumulator.removeAll()
			}

			for classificationRange in file.syntaxClassifications {
				switch classificationRange.kind {
				case _ where classificationRange.kind.isComment == true:
					if commentsAccumulator.last?.kind != classificationRange.kind {
						appendCommentsAccumulator()
					}
					commentsAccumulator.append(classificationRange)
				case .none:
					if
						let text = Self.convertToString(from: classificationRange, withOriginalString: file.contents),
						text.countOccurrences(of: "\n") > 1 {

						appendCommentsAccumulator()
					}
				default:
					appendCommentsAccumulator()
				}
			}
			appendCommentsAccumulator()

			self.allCommentGroupings = rangeGroupings
			self.commentStyle = configuration.commentStyle
			super.init(viewMode: .sourceAccurate)
		}

		override func visitPost(_ node: SourceFileSyntax) {
			for grouping in allCommentGroupings {
				switch grouping {
				case .singleline(let commentGroup):
					visitPostComment(commentGroup)
				case .multiline(let commentGroup):
					visitPostBlockComment(commentGroup)
				case .singlelineDoc(let commentGroup):
					visitPostDocComment(commentGroup)
				case .multilineDoc(let commentGroup):
					visitPostBlockDockComment(commentGroup)
				}
			}
		}

		func visitPostComment(_ commentRangeGroup: [SyntaxClassifiedRange]) {
			guard let firstCommentInGroup = commentRangeGroup.first else { return }
			if case .fail(let reason, let severity) = validateCommentStyle(.singleline) {
				appendViolation(
					at: AbsolutePosition(utf8Offset: firstCommentInGroup.offset),
					reason: reason,
					severity: severity)
				return
			}

			if case .fail(let reason, let severity) = validateSinglelineCommentLineLength(commentRangeGroup.count) {
				appendViolation(
					at: AbsolutePosition(utf8Offset: firstCommentInGroup.offset),
					reason: reason,
					severity: severity)
				return
			}
		}

		func visitPostBlockComment(_ commentRangeGroup: [SyntaxClassifiedRange]) {
			guard let firstCommentInGroup = commentRangeGroup.first else { return }
			if case .fail(let reason, let severity) = validateCommentStyle(.multiline) {
				appendViolation(
					at: AbsolutePosition(utf8Offset: firstCommentInGroup.offset),
					reason: reason,
					severity: severity)
				return
			}
		}

		func visitPostDocComment(_ commentRangeGroup: [SyntaxClassifiedRange]) {

		}

		func visitPostBlockDockComment(_ commentRangeGroup: [SyntaxClassifiedRange]) {

		}

		private func validateCommentStyle(_ style: Style) -> Validation {
			let commentStyle = self.commentStyle ?? style
			self.commentStyle = commentStyle

			switch commentStyle {
			case .mixed:
				return .pass
			default:
				guard style == commentStyle else {
					return .fail(
						reason: "\(style.rawValue.capitalized) comments not allowed",
						severity: configuration.severityConfiguration.severity)
				}
				return .pass
			}
		}

		private func validateSinglelineCommentLineLength(_ lineLength: Int) -> Validation {
			guard
				commentStyle == .mixed,
				let threshold = configuration.lineCommentThreshold
			else { return .pass }

			if lineLength < threshold {
				return .pass
			} else {
				return .fail(
					reason: "Block comments required for comments spanning \(threshold) or more lines",
					severity: configuration.severityConfiguration.severity)
			}
		}

		private static func convertToString(from range: SyntaxClassifiedRange, withOriginalString originalString: String) -> String? {
			let content = Data(originalString.utf8)[range.range.dataRange]
			return String(data: content, encoding: .utf8)
		}

		func replaceRangeWithHyphen(_ range: SyntaxClassifiedRange, originalString: String) -> String? {
			var content = Data(originalString.utf8)
			for i in range.range.dataRange {
				content[i] = "_".utf8.first!
			}
			return String(data: content, encoding: .utf8)
		}

		@discardableResult
		private func appendViolation(
			at position: AbsolutePosition,
			reason: String,
			severity: ViolationSeverity) -> ReasonedRuleViolation {
				let violation = ReasonedRuleViolation(
					position: position,
					reason: reason,
					severity: severity)
				violations.append(violation)
				return violation
			}

		enum Validation { // swiftlint:disable:this nesting
			case pass
			case fail(reason: String, severity: ViolationSeverity)
		}
	}
}

extension ByteSourceRange {
	var dataRange: Range<Int> {
		offset..<endOffset
	}
}
