# SwiftLint

SwiftLint 是一个用于强制检查 Swift 代码风格和规定的一个工具，基本上以 [GitHub's Swift 代码风格指南](https://github.com/github/swift-style-guide)为基础。

SwiftLint Hook 了 [Clang](http://clang.llvm.org) 和 [SourceKit](http://www.jpsim.com/uncovering-sourcekit) 从而能够使用 [AST](http://clang.llvm.org/docs/IntroductionToTheClangAST.html) 来表示源代码文件的更多精确结果。

![Test Status](https://travis-ci.org/realm/SwiftLint.svg?branch=master)
[![codecov.io](https://codecov.io/github/realm/SwiftLint/coverage.svg?branch=master)](https://codecov.io/github/realm/SwiftLint?branch=master)

![](assets/screenshot.png)

## 安装

使用 [Homebrew](http://brew.sh/)

```
brew install swiftlint
```

你也可以通过从[最新的 GitHub 发布地址](https://github.com/realm/SwiftLint/releases/latest)下载`SwiftLint.pkg`然后执行的方式安装 SwiftLint。

你也可以通过 Clone SwiftLint 的 Git 仓库到本地然后执行 `git submodule update --init --recursive; make install` (Xcode 7.1) 编译源代码的方式来安装。

## 用法

### Xcode

整合 SwiftLint 到 Xcode 体系中去从而可以使警告和错误显示到 IDE 上，只需要在 Xcode 中添加一个新的"Run Script Phase"并且包含如下代码即可：

```bash
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

![](assets/runscript.png)

### Atom

整合 SwiftLint 到 [Atom](https://atom.io/) 需要从 APM 安装[`linter-swiftlint`](https://atom.io/packages/linter-swiftlint)包。

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

## 规则

现在只有很少的规则被实现了，但是我们希望 Swift 社区（就是你！）会在以后有更多的贡献，我们鼓励提交 [Pull Requests](CONTRIBUTING.md)。

当前*正在*被实施的规则大多数只是作为一个基础，仅供参考。

想要查看已实现的规则可以查看 [Source/SwiftLintFramework/Rules](Source/SwiftLintFramework/Rules) 目录。

### 在代码中关闭某个规则

可以通过在一个源文件中定义一个如下格式的注释来关闭某个规则：

`// swiftlint:disable <rule>`

在该文件结束之前或者在定义如下格式的匹配注释之前，这条规则都会被禁用：

`// swiftlint:enable <rule>`

例如:

```swift
// swiftlint:disable colon
let noWarning :String = "" // No warning about colons immediately after variable names!
// swiftlint:enable colon
let hasWarning :String = "" // Warning generated about colons immediately after variable names
```

也可以通过添加 `:previous`, `:this` 或者 `:next` 来使关闭或者打开某条规则的命令分别应用于前一行，当前或者后一行代码。

例如:

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

包含的规则:

* `disabled_rules`: 关闭某些默认开启的规则.
* `opt_in_rules`: 一些规则是可选的.
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

MIT 许可。
