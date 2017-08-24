# SwiftLint

SwiftLint 是一个用于强制检查 Swift 代码风格和规定的一个工具，基本上以 [GitHub's Swift 代码风格指南](https://github.com/github/swift-style-guide)为基础。

SwiftLint Hook 了 [Clang](http://clang.llvm.org) 和 [SourceKit](http://www.jpsim.com/uncovering-sourcekit) 从而能够使用 [AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) 来表示源代码文件的更多精确结果。

![Test Status](https://travis-ci.org/realm/SwiftLint.svg?branch=master)
[![codecov.io](https://codecov.io/github/realm/SwiftLint/coverage.svg?branch=master)](https://codecov.io/github/realm/SwiftLint?branch=master)

![](assets/screenshot.png)

该项目遵守 [贡献者契约行为守则](https://realm.io/conduct)。一旦参与，你将被视为支持这一守则。请将
不可接受的行为报告给 [info@realm.io](mailto:info@realm.io)。

## 安装

### 使用 [Homebrew](http://brew.sh/)：

```
brew install swiftlint
```

### 使用 [CocoaPods](https://cocoapods.org)：

将如下代码添加到你的 Podfile 即可：

```ruby
pod 'SwiftLint'
```

在下一次执行 `pod install` 时将会把 SwiftLint 的二进制文件和依赖下载到 `Pods/` 目录下并且将允许你通过 `${PODS_ROOT}/SwiftLint/swiftlint` 在 Script Build Phases 中调用 SwiftLint。

自从 SwiftLint 支持安装某个特定版本后，安装一个指定版本的 SwiftLint 是目前推荐的做法相比较于简单地选择最新版本安装的话（比如通过 Homebrew 安装的话）。

请注意这会将 SwiftLint 二进制文件、所依赖的二进制文件和 Swift 二进制库安装到 `Pods/` 目录下，所以请将此目录添加到版本控制系统中进行跟踪。

### 使用安装包：

你也可以通过从[最新的 GitHub 发布地址](https://github.com/realm/SwiftLint/releases/latest)下载 `SwiftLint.pkg` 然后执行的方式安装 SwiftLint。

### 编译源代码：

你也可以通过 Clone SwiftLint 的 Git 仓库到本地然后执行 `git submodule update --init --recursive; make install` (Xcode 8.3+) 编译源代码的方式来安装。

## 用法

### 报告

我们鼓励您观看本次报告，来获得将 SwiftLint 整合到你的项目中的推荐方式的一个高层次概括：

[![Presentation](assets/presentation.jpg)](https://academy.realm.io/posts/slug-jp-simard-swiftlint/)

### Xcode

整合 SwiftLint 到 Xcode 体系中去从而可以使警告和错误显示到 IDE 上，只需要在 Xcode 中添加一个新的“Run Script Phase”并且包含如下代码即可：

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

![](assets/runscript.png)

或者，脚本看起来应该像这样如果你已经通过 CocoaPods 安装了 SwiftLint：

```bash
"${PODS_ROOT}/SwiftLint/swiftlint"
```

#### 格式化保存 Xcode 插件

在 XCode 中保存时执行 `swiftlint autocorrect`，需要从 Alcatraz 安装 [SwiftLintXcode](https://github.com/ypresto/SwiftLintXcode) 插件。

⚠ ️如果没有禁用 SIP 的话，这个插件在 Xcode 8 或者更新版本的 Xcode 上将不会工作。不推荐此操作。

### AppCode

在 AppCode 中使用 SwiftLint，安装[这个插件](https://plugins.jetbrains.com/plugin/9175)并且在插件设置中配置 SwiftLint 的安装路径即可。`autocorrect` 操作快捷键为 `⌥⏎`。

### Atom

整合 SwiftLint 到 [Atom](https://atom.io/) 需要从 APM 安装 [`linter-swiftlint`](https://atom.io/packages/linter-swiftlint) 包。

### 命令行

```
$ swiftlint help
Available commands:

   autocorrect  Automatically correct warnings and errors
   help         Display general or command-specific help
   lint         Print lint warnings and errors for the Swift files in the current directory (default command)
   rules        Display the list of rules and their identifiers
   version      Display the current version of SwiftLint
```

在包含有需要执行代码分析的 Swift 源码文件的目录下执行 `swiftlint` 命令，会对目录进行递归查找。

当使用 `lint` 或者 `autocorrect` 命令时，你可以通过添加 `--use-script-input-files` 选项并且设置以下实例变量：`SCRIPT_INPUT_FILE_COUNT` 和
`SCRIPT_INPUT_FILE_0`, `SCRIPT_INPUT_FILE_1`... `SCRIPT_INPUT_FILE_{SCRIPT_INPUT_FILE_COUNT}` 的方式来指定一个文件列表（就像被 Xcode 特别是 [`ExtraBuildPhase`](https://github.com/norio-nomura/ExtraBuildPhase) Xcode 插件修改的文件组成的列表，或者类似 Git 工作树中 `git ls-files -m` 命令显示的被修改的文件列表）。

也有类似的用来设置输入文件的环境变量以 [自定义 Xcode script phases](http://indiestack.com/2014/12/speeding-up-custom-script-phases/) 。

### 使用多个 Swift 版本

SwiftLint 工作于 SourceKit 这一层，所以 Swift 版本发生变化时它也能继续工作！

这也是 SwiftLint 轻量化的原因，因为它不需要一个完整的 Swift 编译器，它只是与已经安装在你的电脑上的官方编译器进行通信。

你应该总是使用和你编译代码同样的工具集来执行 SwiftLint。

如果你有多套工具集或者安装了多个不同版本的 Xcode，你可能会需要覆盖 SwiftLint 默认的工具集。

下面这些命令可以控制 SwiftLint 使用哪一个 Swift 工具集来进行工作：

* `$XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`
* `$TOOLCHAIN_DIR` 或者 `$TOOLCHAINS`
* `xcrun -find swift`
* `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`
* `~/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain`

`sourcekitd.framework` 默认需要位于 `usr/lib/` 中，上面传入的路径的子目录中。

你可能也给反向 DNS 符号设置了 `TOOLCHAINS` 环境变量来标记一个特定的 Swift 工具集版本：

```shell
$ TOOLCHAINS=com.apple.dt.toolchain.Swift_2_3 swiftlint autocorrect
```

在 Linux 上，SourceKit 默认需要位于 `/usr/lib/libsourcekitdInProc.so` 或者通过 `LINUX_SOURCEKIT_LIB_PATH` 环境变量进行指定。

### Swift Version Support

这里有一份 SwiftLint 版本和对应该 Swift 版本的对照表作为参考。

| Swift 版本 | 最后一个 SwiftLint 支持版本 |
| ------------- | -------------------------------- |
| Swift 1.x     | SwiftLint 0.1.2                  |
| Swift 2.x     | SwiftLint 0.18.1                 |
| Swift 3.x     | 最新的                            |
| Swift 4.x     | 最新的                            |

## 规则

SwiftLint 已经包含了超过 75 条规则，并且我们希望 Swift 社区（就是你！）会在以后有更多的贡献，我们鼓励提交 [Pull Requests](CONTRIBUTING.md)。

你可以在 [Rules.md](Rules.md) 找到规则的更新列表和更多信息。

你也可以检视 [Source/SwiftLintFramework/Rules](Source/SwiftLintFramework/Rules) 目录来查看它们的实现。

`opt_in_rules` 默认是关闭的（即，你需要在你的配置文件中明确地打开它们）。

什么时候需要将一个规则设为 opt-in 的指南：

* 一个可能会有许多负面作用的规则（例如 `empty_count`）
* 一个过慢的规则
* 一个不通用或者仅在某些特定场景下可用的规则（例如 `force_unwrapping`）

### 在代码中关闭某个规则

可以通过在一个源文件中定义一个如下格式的注释来关闭某个规则：

`// swiftlint:disable <rule>`

在该文件结束之前或者在定义如下格式的匹配注释之前，这条规则都会被禁用：

`// swiftlint:enable <rule>`

例如：

```swift
// swiftlint:disable colon
let noWarning :String = "" // No warning about colons immediately after variable names!
// swiftlint:enable colon
let hasWarning :String = "" // Warning generated about colons immediately after variable names
```

也可以通过添加 `:previous`, `:this` 或者 `:next` 来使关闭或者打开某条规则的命令分别应用于前一行，当前或者后一行代码。

例如：

```swift
// swiftlint:disable:next force_cast
let noWarning = NSNumber() as! Int
let hasWarning = NSNumber() as! Int
let noWarning2 = NSNumber() as! Int // swiftlint:disable:this force_cast
let noWarning3 = NSNumber() as! Int
// swiftlint:disable:previous force_cast
```

执行 `swiftlint rules` 命令可以输出所有可用的规则和他们的标识符组成的列表。

### 配置

可以通过在你需要执行 SwiftLint 的目录下添加一个 `.swiftlint.yml` 文件的方式来配置 SwiftLint。可以被配置的参数有：

包含的规则：

* `disabled_rules`: 关闭某些默认开启的规则。
* `opt_in_rules`: 一些规则是可选的。
* `whitelist_rules`: 不可以和 `disabled_rules` 或者 `opt_in_rules` 并列。类似一个白名单，只有在这个列表中的规则才是开启的。

```yaml
disabled_rules: # 执行时排除掉的规则
  - colon
  - comma
  - control_statement
opt_in_rules: # 一些规则仅仅是可选的
  - empty_count
  - missing_docs
  # 可以通过执行如下指令来查找所有可用的规则:
  # swiftlint rules
included: # 执行 linting 时包含的路径。如果出现这个 `--path` 会被忽略。
  - Source
excluded: # 执行 linting 时忽略的路径。 优先级比 `included` 更高。
  - Carthage
  - Pods
  - Source/ExcludedFolder
  - Source/ExcludedFile.swift

# 可配置的规则可以通过这个配置文件来自定义
# 二进制规则可以设置他们的严格程度
force_cast: warning # 隐式
force_try:
  severity: warning # 显式
# 同时有警告和错误等级的规则，可以只设置它的警告等级
# 隐式
line_length: 110
# 可以通过一个数组同时进行隐式设置
type_body_length:
  - 300 # warning
  - 400 # error
# 或者也可以同时进行显式设置
file_length:
  warning: 500
  error: 1200
# 命名规则可以设置最小长度和最大程度的警告/错误
# 此外它们也可以设置排除在外的名字
type_name:
  min_length: 4 # 只是警告
  max_length: # 警告和错误
    warning: 40
    error: 50
  excluded: iPhone # 排除某个名字
identifier_name:
  min_length: # 只有最小长度
    error: 4 # 只有错误
  excluded: # 排除某些名字
    - id
    - URL
    - GlobalAPIKey
reporter: "xcode" # 报告类型 (xcode, json, csv, checkstyle, junit, html, emoji)
```

#### 定义自定义规则

你可以用如下语法在你的配置文件里定义基于正则表达式的自定义规则：

```yaml
custom_rules:
  pirates_beat_ninjas: # 规则标识符
    name: "Pirates Beat Ninjas" # 规则名称，可选
    regex: "([n,N]inja)" # 匹配的模式
    match_kinds: # 需要匹配的语法类型，可选
      - comment
      - identifier
    message: "Pirates are better than ninjas." # 提示信息，可选
    severity: error # 提示的级别，可选
  no_hiding_in_strings:
    regex: "([n,N]inja)"
    match_kinds: string
```

输出大概可能是这个样子的：

![](assets/custom-rule.png)

你可以通过提供一个或者多个 `match_kinds` 的方式来对匹配进行筛选，它会将含有不包括在列表中的语法类型的匹配排除掉。这里有全部可用的语法类型：

* argument
* attribute.builtin
* attribute.id
* buildconfig.id
* buildconfig.keyword
* comment
* comment.mark
* comment.url
* doccomment
* doccomment.field
* identifier
* keyword
* number
* objectliteral
* parameter
* placeholder
* string
* string_interpolation_anchor
* typeidentifier

#### 嵌套配置

SwiftLint 支持通过嵌套配置文件的方式来对代码分析过程进行更加细致的控制。

* 在你需要的目录引入 `.swiftlint.yml`。
* 在目录结构必要的地方引入额外的 `.swiftlint.yml` 文件。
* 每个文件被检查时会使用在文件所在目录下的或者父目录的更深层目录下的配置文件。否则根配置文件将会生效。
* `excluded` 和 `included` 在嵌套结构中会被忽略。

### 自动更正

SwiftLint 可以自动修正某些错误，磁盘上的文件会被一个修正后的版本覆盖。

请确保在对文件执行 `swiftlint autocorrect` 之前有对它们做过备份，否则的话有可能导致重要数据的丢失。

因为在执行自动更正修改某个文件后很有可能导致之前生成的代码检查信息无效或者不正确，所以当在执行代码更正时标准的检查是无法使用的。

## 协议

[MIT 许可。](LICENSE)

## 关于

<img src="assets/realm.png" width="184" />

SwiftLint 是由 Realm Inc 建立和维护的。Realm 的名字和标志是属于 Realm Inc 的注册商标。

我们 :heart: 开源软件！看一下[我们的其他开源项目](https://github.com/realm)，瞅一眼[我们的博客](https://realm.io/news)，或者在推特上跟我们唠唠嗑([@realm](https://twitter.com/realm))。
