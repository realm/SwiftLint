#!/usr/bin/env ruby

# This script marks/closes stale issues. It marks an issue as stale if it has not seen any activity in the last 4 months
# and is marked with 'help' or 'repro-needed' label, that is, those issues that awaiting a response from the author. If
# an issue is marked as stale and it sees activity within the last month, the script removes the 'stale' label. If an
# issue is marked as stale and it has not seen any activity in the last month, the script closes the issue with a
# comment.

require 'time'
require 'json'

# Usage: stale_issues.rb <repository> [dry_run]
$repository = ARGV[0]
$dry_run = ARGV[1] == 'true'

date_format = "%Y-%m-%dT%H:%M:%SZ"
closing_comment = "This issue is being closed due to inactivity. \
Please feel free to reopen if you have more information."
stale_comment = "This issue has been marked as stale because it has not seen any activity \
in the last 4 months. It is going to be closed soon if it stays inactive."

one_month_ago = (Time.now - 30 * 24 * 60 * 60).utc.strftime(date_format)
four_months_ago = (Time.now - 4 * 30 * 24 * 60 * 60).utc.strftime(date_format)

def run(issue)
    if $dry_run
        url = "https://github.com/#{$repository}/issues/#{issue}"
        case RUBY_PLATFORM
        when /linux/
            system("xdg-open #{url}")
        when /darwin/
            system("open #{url}")
        else
            puts url
        end
    else
        yield.each { |cmd| system(cmd) }
    end
end

def created_by_maintainer?(comment)
    comment && (comment['author'] == 'github-actions[bot]' || comment['authorAssociation'] == 'COLLABORATOR')
end

issues_query = "repo:#{$repository} is:issue is:open label:stale,help,repro-needed"
issues = JSON.parse(`gh issue list --json number,comments,labels,updatedAt --search '#{issues_query}'`)

for issue in issues do
    number = issue['number']
    comments = issue['comments']
    last_comment_by_user = comments.filter { |comment| !created_by_maintainer?(comment) }.last
    last_comment_by_user_date = last_comment_by_user['createdAt'] if last_comment_by_user
    if !issue['labels'].filter { |label| label['name'] == 'stale' }.empty?
        if last_comment_by_user_date && last_comment_by_user_date > one_month_ago
            puts "Removing 'stale' label from issue ##{number} ..."
            run(number) { || ["gh issue edit #{number} --remove-label stale"] }
        elseif issue['updatedAt'] < one_month_ago
            puts "Closing issue ##{number} ..."
            run(number) { || ["gh issue close #{number} --comment '#{closing_comment}'"] }
        end
    elsif created_by_maintainer?(comments.last) && comments.last['createdAt'] < four_months_ago
        if !issue['labels'].filter { |label| !%w(help repro-needed).include?(label['name']) }.empty?
            next
        end
        puts "Adding 'stale' label to issue ##{number} ..."
        run(number) { || [
            "gh issue edit #{number} --add-label stale",
            "gh issue comment #{number} --body '#{stale_comment}'"
        ] }
    end
end
