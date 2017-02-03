require 'open3'

# Warn when there is a big PR
warn('Big PR') if git.lines_of_code > 500

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !git.modified_files.grep(/Source/).empty?
has_test_changes = !git.modified_files.grep(/Tests/).empty?
has_dangerfile_changes = !git.modified_files.grep(/Dangerfile/).empty?

# Add a CHANGELOG entry for app changes
if !git.modified_files.include?('CHANGELOG.md') && has_app_changes
  fail("Please include a CHANGELOG entry to credit yourself! \nYou can find it at [CHANGELOG.md](https://github.com/realm/SwiftLint/blob/master/CHANGELOG.md).")
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

# Non-trivial amounts of app changes without tests
if git.lines_of_code > 50 && has_app_changes && !has_test_changes
  warn 'This PR may need tests.'
end

# Run OSSCheck if there were app changes
if has_app_changes || has_dangerfile_changes
  def non_empty_lines(lines)
    lines.split(/\n+/).reject(&:empty?)
  end

  def parse_line(line)
    line.split(':', 2).last.strip
  end

  lines = nil
  Bundler.with_clean_env do
    Open3.popen3('script/oss-check') do |_, stdout, stderr, _|
      while char = stdout.getc
        print char
      end

      lines = stderr.read.chomp
    end
  end

  non_empty_lines(lines).each do |line|
    if line.start_with? 'Message:'
      message parse_line(line)
    elsif line.start_with? 'Warning:'
      warn parse_line(line)
    elsif line.start_with? 'Error:'
      fail parse_line(line)
    end
  end
end
