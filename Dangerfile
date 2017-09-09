require 'open3'

# Warn when there is a big PR
warn('Big PR') if git.lines_of_code > 500

# Ensure a clean commit history
if git.commits.any? { |c| c.message =~ /^Merge branch '#{github.branch_for_base}'/ }
  fail('Please rebase to get rid of the merge commits in this PR')
end

modified_files = git.modified_files + git.added_files

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !modified_files.grep(/Source/).empty?
has_test_changes = !modified_files.grep(/Tests/).empty?
has_danger_changes = !modified_files.grep(/Dangerfile|script\/oss-check|Gemfile/).empty?
has_rules_changes = !modified_files.grep(/Source\/SwiftLintFramework\/Rules/).empty?
has_rules_docs_changes = modified_files.include?('Rules.md')

# Add a CHANGELOG entry for app changes
if !modified_files.include?('CHANGELOG.md') && has_app_changes
  warn("Please include a CHANGELOG entry to credit yourself! \nYou can find it at [CHANGELOG.md](https://github.com/realm/SwiftLint/blob/master/CHANGELOG.md).")
    markdown <<-MARKDOWN
Here's an example of your CHANGELOG entry:
```markdown
* #{github.pr_title}.#{'  '}
  [#{github.pr_author}](https://github.com/#{github.pr_author})
  [#issue_number](https://github.com/realm/SwiftLint/issues/issue_number)
```
*note*: There are two invisible spaces after the entry's text.
MARKDOWN
end

return unless has_app_changes || has_danger_changes

# Non-trivial amounts of app changes without tests
if git.lines_of_code > 50 && has_app_changes && !has_test_changes
  warn 'This PR may need tests.'
end

# Run OSSCheck if there were app changes

def non_empty_lines(lines)
  lines.split(/\n+/).reject(&:empty?)
end

def parse_line(line)
  line.split(':', 2).last.strip
end

file = Tempfile.new('violations')

Open3.popen3("script/oss-check -v 2> #{file.path}") do |_, stdout, _, _|
  while char = stdout.getc
    print char
  end
end

lines = file.read.chomp
file.close
file.unlink

non_empty_lines(lines).each do |line|
  if line.include? 'Permanently added the RSA host key for IP address'
    # Don't report to Danger
  elsif line.start_with? 'Message:'
    message parse_line(line)
  elsif line.start_with? 'Warning:'
    warn parse_line(line)
  elsif line.start_with? 'Error:'
    fail parse_line(line)
  end
end
