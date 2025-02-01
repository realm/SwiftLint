import Testing

@Suite
struct StringExtensionTests {
    @Test
    func relativePathExpression() {
        #expect("Folder/Test" == "Root/Folder/Test".path(relativeTo: "Root"))
        #expect("Test" == "Root/Folder/Test".path(relativeTo: "Root/Folder"))
        #expect("" == "Root/Folder/Test".path(relativeTo: "Root/Folder/Test"))
        #expect("../Test" == "Root/Folder/Test".path(relativeTo: "Root/Folder/SubFolder"))
        #expect("../.." == "Root".path(relativeTo: "Root/Folder/SubFolder"))
        #expect("../../OtherFolder/Test" == "Root/OtherFolder/Test".path(relativeTo: "Root/Folder/SubFolder"))
        #expect("../MyFolder123" == "Folder/MyFolder123".path(relativeTo: "Folder/MyFolder"))
        #expect("../MyFolder123" == "Folder/MyFolder123".path(relativeTo: "Folder/MyFolder/"))
        #expect("Test" == "Root////Folder///Test/".path(relativeTo: "Root//Folder////"))
        #expect("Root/Folder/Test" == "Root/Folder/Test/".path(relativeTo: ""))
    }

    @Test
    func indent() {
        #expect("string".indent(by: 3) == "   string")
        #expect(" string".indent(by: 2) == "   string")
        #expect(
            """
            1
            2
            3
            """.indent(by: 2) == """
                  1
                  2
                  3
                """
        )
    }

    @Test
    func characterPosition() {
        #expect("string".characterPosition(of: -1) == nil)
        #expect("string".characterPosition(of: 0) == 0)
        #expect("string".characterPosition(of: 1) == 1)
        #expect("string".characterPosition(of: 6) == nil)
        #expect("string".characterPosition(of: 7) == nil)

        #expect("s🤵🏼‍♀️s".characterPosition(of: 0) == 0)
        #expect("s🤵🏼‍♀️s".characterPosition(of: 1) == 1)
        for bytes in 2...17 {
            #expect("s🤵🏼‍♀️s".characterPosition(of: bytes) == nil)
        }
        #expect("s🤵🏼‍♀️s".characterPosition(of: 18) == 2)
        #expect("s🤵🏼‍♀️s".characterPosition(of: 19) == nil)
    }
}
