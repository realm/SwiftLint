import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct CollectionAlignmentRule: Rule {
    var configuration = CollectionAlignmentConfiguration()

    static let description = RuleDescription(
        identifier: "collection_alignment",
        name: "Collection Element Alignment",
        description: "All elements in a collection literal should be vertically aligned",
        kind: .style,
        nonTriggeringExamples: Examples(alignColons: false).nonTriggeringExamples,
        triggeringExamples: Examples(alignColons: false).triggeringExamples
    )
}

private extension CollectionAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // Computed once per file: `SourceLocationConverter.sourceLines` materializes every line of the
        // file as a new `[String]` on each access, and the dictionary path below reads it once per
        // element, which is quadratic in files holding large dictionary literals.
        private lazy var sourceLines = locationConverter.sourceLines

        override func visitPost(_ node: ArrayExprSyntax) {
            let locations = node.elements.map { element in
                locationConverter.location(for: element.positionAfterSkippingLeadingTrivia)
            }
            violations.append(contentsOf: validate(keyLocations: locations, inGraphemeColumns: false))
        }

        override func visitPost(_ node: DictionaryElementListSyntax) {
            let locations = node.map { element in
                let position = configuration.alignColons ? element.colon.positionAfterSkippingLeadingTrivia :
                    element.key.positionAfterSkippingLeadingTrivia
                return locationConverter.location(for: position)
            }
            violations.append(contentsOf: validate(keyLocations: locations, inGraphemeColumns: true))
        }

        private func validate(keyLocations: [SourceLocation],
                              inGraphemeColumns: Bool) -> [AbsolutePosition] {
            guard keyLocations.count >= 2 else {
                return []
            }

            // Only the first key and keys starting a new line are ever compared, so resolving
            // grapheme columns on demand keeps single-line literals from reading the source lines
            // at all.
            var firstKeyColumn: Int?
            var positions = [AbsolutePosition]()
            for index in keyLocations.indices.dropFirst() {
                let location = keyLocations[index]
                guard keyLocations[index - 1].line < location.line else {
                    continue
                }
                let firstColumn = firstKeyColumn
                    ?? column(of: keyLocations[0], inGraphemeColumns: inGraphemeColumns)
                firstKeyColumn = firstColumn
                let locationColumn = column(of: location, inGraphemeColumns: inGraphemeColumns)
                guard firstColumn != locationColumn else {
                    continue
                }
                positions.append(locationConverter.position(ofLine: location.line, column: locationColumn))
            }
            return positions
        }

        private func column(of location: SourceLocation, inGraphemeColumns: Bool) -> Int {
            guard inGraphemeColumns,
                  let graphemeClusters = String(
                      sourceLines[location.line - 1].utf8.prefix(location.column - 1)
                  ) else {
                return location.column
            }
            return graphemeClusters.count + 1
        }
    }
}

extension CollectionAlignmentRule {
    struct Examples {
        private let alignColons: Bool

        init(alignColons: Bool) {
            self.alignColons = alignColons
        }

        var triggeringExamples: [Example] {
            let examples = alignColons ? alignColonsTriggeringExamples : alignLeftTriggeringExamples
            return examples + sharedTriggeringExamples
        }

        var nonTriggeringExamples: [Example] {
            let examples = alignColons ? alignColonsNonTriggeringExamples : alignLeftNonTriggeringExamples
            return examples + sharedNonTriggeringExamples
        }

        private var alignColonsTriggeringExamples: [Example] {
            #examples([
                """
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz"↓: 2,
                    "buzz"↓: 2
                ])
                """,
                """
                let abc = [
                    "alpha": "a",
                    "beta"↓: "b",
                    "gamma": "c",
                    "delta": "d",
                    "epsilon"↓: "e"
                ]
                """,
                """
                var weirdColons = [
                    "a"    :  1,
                    "b"  ↓:2,
                    "c"    :      3
                ]
                """,
            ])
        }

        private var alignColonsNonTriggeringExamples: [Example] {
            #examples([
                """
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   "fizz": 2,
                   "buzz": 2
                ])
                """,
                """
                let abc = [
                    "alpha": "a",
                     "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  "epsilon": "e"
                ]
                """,
                """
                var weirdColons = [
                    "a"    :  1,
                      "b"  :2,
                       "c" :      3
                ]
                """,
                """
                NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                  .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                """,
            ])
        }

        private var alignLeftTriggeringExamples: [Example] {
            #examples([
                """
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                   ↓"fizz": 2,
                   ↓"buzz": 2
                ])
                """,
                """
                let abc = [
                    "alpha": "a",
                     ↓"beta": "b",
                    "gamma": "g",
                    "delta": "d",
                  ↓"epsilon": "e"
                ]
                """,
                """
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                    ↓"dinner": "burger"
                ]
                """,
            ])
        }

        private var alignLeftNonTriggeringExamples: [Example] {
            #examples([
                """
                doThings(arg: [
                    "foo": 1,
                    "bar": 2,
                    "fizz": 2,
                    "buzz": 2
                ])
                """,
                """
                let abc = [
                    "alpha": "a",
                    "beta": "b",
                    "gamma": "g",
                    "delta": "d",
                    "epsilon": "e"
                ]
                """,
                """
                let meals = [
                                "breakfast": "oatmeal",
                                "lunch": "sandwich",
                                "dinner": "burger"
                ]
                """,
                """
                NSAttributedString(string: "…", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .regular),
                                                             .foregroundColor: UIColor(white: 0, alpha: 0.2)])
                """,
            ])
        }

        private var sharedTriggeringExamples: [Example] {
            #examples([
                """
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                        ↓CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """,
                """
                var evenNumbers: Set<Int> = [
                    2,
                  ↓4,
                    6
                ]
                """,
            ])
        }

        private var sharedNonTriggeringExamples: [Example] {
            #examples([
                """
                let coordinates = [
                    CLLocationCoordinate2D(latitude: 0, longitude: 33),
                    CLLocationCoordinate2D(latitude: 0, longitude: 66),
                    CLLocationCoordinate2D(latitude: 0, longitude: 99)
                ]
                """,
                """
                var evenNumbers: Set<Int> = [
                    2,
                    4,
                    6
                ]
                """,
                """
                let abc = [1, 2, 3, 4]
                """,
                """
                let abc = [
                    1, 2, 3, 4
                ]
                """,
                """
                let abc = [
                    "foo": "bar", "fizz": "buzz"
                ]
                """,
            ])
        }
    }
}
