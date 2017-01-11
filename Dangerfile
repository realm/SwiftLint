require 'open3'

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
if has_app_changes
  @repos = [
    'Alamofire/Alamofire',
    'apple/swift',
    'JohnCoates/Aerial',
    'jpsim/SourceKitten',
    'Moya/Moya',
    'realm/realm-cocoa'
  ]

  @commits = {}
  @branch_durations = {}
  @master_durations = {}

  def generate_reports(clone, branch)
    Dir.chdir('osscheck') do
      @repos.each do |repo|
        repo_name = repo.partition('/').last
        if clone
          puts "Cloning #{repo_name}"
          `git clone "https://github.com/#{repo}" --depth 1 2> /dev/null`
          if repo_name == 'swift'
            File.open("swift/.swiftlint.yml", 'w') do |file|
              file << 'included: stdlib'
            end
          end
        end
        Dir.chdir(repo_name) do
          iterations = 5
          print "Linting #{iterations} iterations of #{repo_name} with #{branch}: 1"
          @commits[repo] = `git rev-parse HEAD`
          durations = []
          start = Time.now
          command = '../../.build/release/swiftlint lint --no-cache'
          File.open("../#{branch}_reports/#{repo_name}.txt", 'w') do |file|
            Open3.popen3(command) do |_, stdout, _, _|
              file << stdout.read.chomp
            end
          end
          durations += [Time.now - start]
          for i in 2..iterations
            print "..#{i}"
            start = Time.now
            Open3.popen3(command) { |_, stdout, _, _| stdout.read }
            durations += [Time.now - start]
          end
          puts ''
          average_duration = (durations.reduce(:+) / iterations).round(2)
          if branch == 'branch'
            @branch_durations[repo] = average_duration
          else
            @master_durations[repo] = average_duration
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
  puts 'Building branch'
  `swift build -c release`
  # Generate branch reports
  generate_reports(true, 'branch')
  # Build master
  `git fetch`
  `git checkout origin/master`
  puts 'Building master'
  `swift build -c release`
  unless $?.success?
    # Couldn't build, start fresh
    FileUtils.rm_rf %w(Packages .build)
    return_value = nil
    Open3.popen3('swift build -c release') do |_, stdout, _, wait_thr|
      puts stdout.read.chomp
      return_value = wait_thr.value
    end
    unless return_value.success?
      fail 'Could not build master'
      return
    end
  end
  # Generate master reports
  generate_reports(false, 'master')
  # Diff and report changes to Danger
  @repos.each do |repo|
    @repo_name = repo.partition('/').last
    def non_empty_lines(path)
      File.read(path).split(/\n+/).reject(&:empty?)
    end
    branch = non_empty_lines("osscheck/branch_reports/#{@repo_name}.txt")
    master = non_empty_lines("osscheck/master_reports/#{@repo_name}.txt")
    @repo = repo
    def convert_to_link(string)
      string.sub!("/Users/distiller/SwiftLint/osscheck/#{@repo_name}", '')
      string.sub!('.swift:', '.swift#L')
      string = string.partition(': warning:').first.partition(': error:').first
      "https://github.com/#{@repo}/blob/#{@commits[@repo]}#{string}"
    end
    (master - branch).each do |fixed|
      message "This PR fixed a violation in #{@repo_name}: [#{fixed}](#{convert_to_link(fixed)})"
    end
    (branch - master).each do |violation|
      warn "This PR introduced a violation in #{@repo_name}: [#{violation}](#{convert_to_link(violation)})"
    end
  end
  @branch_durations.each do |repo, branch_duration|
    master_duration = @master_durations[repo]
    percent_change = 100 * (master_duration - branch_duration) / master_duration
    faster_slower = nil
    if branch_duration < master_duration
      faster_slower = 'faster'
    else
      faster_slower = 'slower'
      percent_change *= -1
    end
    repo_name = repo.partition('/').last
    message "Linting #{repo_name} with this PR took #{branch_duration}s " \
            "vs #{master_duration}s on master (#{percent_change.to_i}\% #{faster_slower})"
  end
  # Clean up
  FileUtils.rm_rf('osscheck')
end
