import SwiftLintCore

internal struct SortedImportsRuleExamples {
    private static let groupByAttributesConfiguration = ["grouping": "attributes"]

    static let nonTriggeringExamples = #examples([
        """
        import AAA
        import BBB
        import CCC
        import DDD
        """,
        """
        import Alamofire
        import API
        """,
        """
        import labc
        import Ldef
        """,
        """
        // comment
        import AAA
        import BBB
        import CCC
        """,
        """
        @testable import AAA
        import   CCC
        """,
        """
        import AAA
        @testable import   CCC
        """,
        """
        import EEE.A
        import FFF.B
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import CCC
        import DDD.B
        #endif
        import AAA
        import BBB
        """,
        """
        // header

        import DDD
        import SSS

        // some comment
        import FFF // a comment
        """.asExample(excludeFromDocumentation: true),
        """
        // header

        import DDD
        import FFF

        // some comment
        import AAA // a comment
        import NNN
        """.asExample(excludeFromDocumentation: true),
        """
        @testable import AAA
          @testable import BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @testable import BBB
          import AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @_exported import BBB
          @testable import AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @_exported @testable import BBB
          import AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @_exported @testable import BBB
          public import BBB
          import AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        public import FFF
        package import EEE
        internal import DDD
        fileprivate import CCC
        private import BBB
        import AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @_exported @testable public import BBB
        @_exported @testable private import BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
        @_exported public import BBB
        @_exported @testable import BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
    ]).skipMultiByteOffsetTests()

    static let triggeringExamples = #examples([
        """
        import AAA
        import ZZZ
        import ↓BBB
        import CCC
        """,
        """
        import DDD
        // comment
        import ↓CCC
        import ↓AAA
        """,
        """
        @testable import CCC
        import   ↓AAA
        """,
        """
        import CCC
        @testable import   ↓AAA
        """,
        """
        import FFF.B
        import ↓EEE.A
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import DDD.B
        import ↓CCC
        #endif
        import AAA
        import BBB
        """,
        """
          @testable import BBB
        @testable import ↓AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          import AAA
        @testable import ↓BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          import BBB
        @testable import ↓AAA
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          @testable import AAA
        @_exported import ↓BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          import AAA
        @_exported @testable import ↓BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          import AAA
          public import ↓BBB
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
        """
          import AAA
          private import ↓BBB
          fileprivate import ↓CCC
          internal import ↓DDD
          package import ↓EEE
          public import ↓FFF
        """.asExample(configuration: groupByAttributesConfiguration, excludeFromDocumentation: true),
    ])

    static let corrections = #corrections([
        """
        import AAA
        import ZZZ
        import BBB
        import CCC
        """.asExample(testMultiByteOffsets: false):
            """
            import AAA
            import BBB
            import CCC
            import ZZZ
            """,
        """
        import BBB // comment
        import AAA
        """.asExample(testMultiByteOffsets: false):
            """
              import AAA
              import BBB // comment
              """,
        """
        import BBB
        // comment
        import CCC
        import AAA
        """.asExample(testMultiByteOffsets: false):
            """
            import AAA
            import BBB
            // comment
            import CCC
            """,
        """
        @testable import CCC
        import  AAA
        """.asExample(testMultiByteOffsets: false):
            """
              import  AAA
              @testable import CCC
              """,
        """
        import CCC
        @testable import  AAA
        """.asExample(testMultiByteOffsets: false):
            """
              @testable import  AAA
              import CCC
              """,
        """
        import FFF.B
        import EEE.A
        #if os(Linux)
        import DDD.A
        import EEE.B
        #else
        import DDD.B
        import CCC
        #endif
        import AAA
        import BBB
        """.asExample(testMultiByteOffsets: false):
            """
            import EEE.A
            import FFF.B
            #if os(Linux)
            import DDD.A
            import EEE.B
            #else
            import CCC
            import DDD.B
            #endif
            import AAA
            import BBB
            """,
        """
          // comment

          import BBB
          import AAA
        """:
            """
              // comment

              import AAA
              import BBB
            """,
        """
        // header

        import DDD
        import SSS

        // some comment
        import FFF // a comment
        """:
            """
            // header

            import DDD
            import SSS

            // some comment
            import FFF // a comment
            """,
        """
        // header

        // comment
        import BBB
        // another comment
        import AAA
        """:
            """
            // header

            // another comment
            import AAA
            // comment
            import BBB
            """,
        """
        // header

        import class CCC
        import BBB
        import LLL
        """:
            """
            // header

            import BBB
            import class CCC
            import LLL
            """,
        """
        // header

        import AAA
        import class CCC2.View
        import CCC1
        """:
            """
            // header

            import AAA
            import CCC1
            import class CCC2.View
            """,
        """
          @testable import BBB
        @testable import AAA
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @testable import AAA
              @testable import BBB
            """,
        """
          import AAA
        @testable import BBB
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @testable import BBB
              import AAA
            """,
        """
          import BBB
        @testable import AAA
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @testable import AAA
              import BBB
            """,
        """
          @testable import AAA
        @_exported import BBB
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @_exported import BBB
              @testable import AAA
            """,
        """
          import AAA
        @_exported @testable import BBB
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @_exported @testable import BBB
              import AAA
            """,
        """
          public import AAA
        @_exported @testable import BBB
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            @_exported @testable import BBB
              public import AAA
            """,
        """
        import AAA
        private import BBB
        fileprivate import CCC
        internal import DDD
        package import EEE
        // A comment that needs to be shifted along with the import
        public import FFF
        """.asExample(configuration: groupByAttributesConfiguration, testMultiByteOffsets: false):
            """
            // A comment that needs to be shifted along with the import
            public import FFF
            package import EEE
            internal import DDD
            fileprivate import CCC
            private import BBB
            import AAA
            """,
    ])
}
