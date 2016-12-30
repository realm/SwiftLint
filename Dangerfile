# Warn when there is a big PR
warn('Big PR') if git.lines_of_code > 500

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !git.modified_files.grep(/Source/).empty?
has_test_changes = !git.modified_files.grep(/Tests/).empty?

# Add a CHANGELOG entry for app changes
if !git.modified_files.include?('CHANGELOG.md') && has_app_changes
  fail("Please include a CHANGELOG entry to credit yourself! \nYou can find it at [CHANGELOG.md](https://github.com/realm/SwiftLint/blob/master/CHANGELOG.md).")
    markdown <<-MARKDOWN
Here's an example of your CHANGELOG entry:
```markdown
* #{github.pr_title}#{'  '}
  [#{github.pr_author}](https://github.com/#{github.pr_author})
  [#issue_number](https://github.com/realm/SwiftLint/issues/issue_number)
```
*note*: There are two invisible spaces after the entry's text.
MARKDOWN
end

# Non-trivial amounts of app changes without tests
if git.lines_of_code > 50 && has_app_changes && !has_test_changes
  warn 'This PR may need tests.'
end

# Run OSSCheck if there were app changes
if has_app_changes
  @repos = [
    'JohnCoates/Aerial',
    'jpsim/SourceKitten',
    'Moya/Moya',
    'realm/realm-cocoa'
  ]

  def generate_reports(clone, branch)
    Dir.chdir('osscheck') do
      @repos.each do |repo|
        `git clone "https://github.com/#{repo}" --depth 1` if clone
        repo_name = repo.partition('/').last
        Dir.chdir(repo_name) do
          File.open("../#{branch}_reports/#{repo_name}.txt", 'w') do |file|
            file.puts `../../.build/debug/swiftlint`
          end
        end
      end
    end
  end

  # Prep
  ['osscheck/branch_reports', 'osscheck/master_reports'].each do |dir|
    FileUtils.mkdir_p(dir)
  end
  # Build branch
  `swift build`
  # Generate branch reports
  generate_reports(true, 'branch')
  # Build master
  `git checkout master`
  `git pull`
  `git submodule update --init --recursive`
  `swift build`
  # Generate master reports
  generate_reports(false, 'master')
  # Diff and report changes to Danger
  @repos.each do |repo|
    repo_name = repo.partition('/').last
    branch = File.read("osscheck/branch_reports/#{repo_name}.txt").split(/\n+/).reject { |c| c.empty? }
    master = File.read("osscheck/master_reports/#{repo_name}.txt").split(/\n+/).reject { |c| c.empty? }
    (master - branch).each do |fixed|
      message "This PR fixed a violation in #{repo_name}: #{fixed}"
    end
    (branch - master).each do |violation|
      warn "This PR introduced a violation in #{repo_name}: #{violation}"
    end
  end
  # Clean up
  FileUtils.rm_rf('osscheck')
end
