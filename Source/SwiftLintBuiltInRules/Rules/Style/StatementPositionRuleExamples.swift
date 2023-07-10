internal struct StatementPositionRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
            if true {
                foo()
            } else {
                bar()
            }
        """),
        Example("""
            if true {
                foo
            } else if true {
                bar()
            } else {
                return
            }
        """),
        Example("""
            do {
                foo()
            } catch {
                bar()
            }
        """),
        Example("""
            do {
                foo()
            } catch let error {
                bar()
            } catch {
                return
            }
        """),
        Example("""
            struct A { let catchphrase: Int }
            let a = A(
                catchphrase: 0
            )
        """),
        Example("""
            struct A { let `catch`: Int }
            let a = A(
                `catch`: 0
            )
        """)
    ]

    static let triggeringExamples = [
        Example("""
            if true {
                foo()
            }↓else {
                bar()
            }
        """),
        Example("""
            if true {
                foo()
            }↓    else if true {
                bar()
            }
        """),
        Example("""
            if true {
                foo()
            }↓
            else true {
                bar()
            }
        """),
        Example("""
            do {
                foo()
            }↓catch {
                bar()
            }
        """),
        Example("""
            do {
                foo()
            }↓    catch {
                bar()
            }
        """),
        Example("""
            do {
                foo()
            }↓
            catch {
                bar()
            }
        """)
    ]

    static let corrections = [
        Example("""
            if true {
                foo()
            }↓
            else {
                bar()
            }
        """): Example("""
                if true {
                    foo()
                } else {
                    bar()
                }
            """),
        Example("""
            if true {
                foo()
            }↓   else if true {
                bar()
            }
        """): Example("""
                if true {
                    foo()
                } else if true {
                    bar()
                }
            """),
        Example("""
            do {
                foo()
            }↓
            catch {
                bar()
            }
        """): Example("""
                do {
                    foo()
                } catch {
                    bar()
                }
            """),
        Example("""
            do {
                foo()
            }↓    catch {
                bar()
            }
        """): Example("""
                do {
                    foo()
                } catch {
                    bar()
                }
            """)
    ]
}
