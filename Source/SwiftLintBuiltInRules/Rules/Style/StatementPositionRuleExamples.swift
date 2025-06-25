struct StatementPositionRuleExamples {
    static let nonTriggeringExamples = [
        // Single line examples
        Example("if true { } else if false { }"),
        Example("if true { } else { }"),
        Example("do { } catch { }"),
        Example("do { let a = 1 } catch let error { }"),
        Example("\"}else{\""),
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
        """),
        // Multi-line examples
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
        """),
    ]

    static let triggeringExamples = [
        // Single line examples
        Example("if true { ↓}else if false { }"),
        Example("if true { ↓}  else { }"),
        Example("""
        do { ↓}
        catch { }
        """),
        Example("""
        do {
            let a = 1
        ↓}
        \t  catch { }
        """),
        // Multi-line examples
        Example("""
        if true {
            foo()
        ↓}else {
            bar()
        }
        """),
        Example("""
        if true {
            foo()
        ↓}    else if true {
            bar()
        }
        """),
        Example("""
        if true {
            foo()
        ↓}
        else {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓}catch {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓}    catch {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓}
        catch {
            bar()
        }
        """),
        // Comments don't prevent violation detection
        Example("""
        if true {
            foo()
        ↓} // comment
        else {
            bar()
        }
        """),
        Example("""
        do {
            foo()
        ↓}
        // comment
        catch {
            bar()
        }
        """),
    ]

    static let corrections = [
        // Single line examples
        Example("""
        if true { ↓}
         else { }
        """): Example("if true { } else { }"),
        Example("""
        if true { ↓}
           else if false { }
        """): Example("if true { } else if false { }"),
        Example("""
        do { ↓}
         catch { }
        """): Example("do { } catch { }"),
        // Multi-line examples
        Example("""
        if true {
            foo()
        ↓}
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
        ↓}   else if true {
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
        ↓}
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
        ↓}    catch {
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
        ↓}
        // comment
        catch {
            bar()
        }
        """): Example("""
        do {
            foo()
        ↓}
        // comment
        catch {
            bar()
        }
        """, allowsViolationsInCorrections: true),
    ]

    // MARK: - Uncuddled Examples

    static let uncuddledNonTriggeringExamples = [
        Example("""
        if true {
          }
          else if false {
          }
        """),
        Example("""
        if condition {
            }
            else {
            }
        """),
        Example("""
        do {
          }
          catch {
          }
        """),
        Example("""
        do {
          }

          catch {
          }
        """),
        Example("""
        do {


          }
          catch {
          }
        """),
        Example("\"}\nelse{\""),
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
        """),
    ]

    static let uncuddledTriggeringExamples = [
        Example("""
        if true {
          ↓}else if false {
          }
        """),
        Example("""
        if condition {
        ↓}
          else {
        }
        """),
        Example("""
        do {
          ↓}
        catch {
        }
        """),
        Example("""
        do {
        ↓}
        \t  catch {
        }
        """),
    ]

    static let uncuddledCorrections = [
        Example("""
        if true {
          }else if false {
          }
        """): Example("""
        if true {
          }
          else if false {
          }
        """),
        Example("""
        if condition {
        }
          else {
        }
        """): Example("""
        if condition {
        }
        else {
        }
        """),
        Example("""
        do {
          }
        catch {
        }
        """): Example("""
        do {
          }
          catch {
        }
        """),
        Example("""
        do {
        }
        \t  catch {
        }
        """): Example("""
        do {
        }
        catch {
        }
        """),
    ]
}
