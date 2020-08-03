#!/usr/bin/env ruby
require_relative '../furik.rb'
require 'thor'

module Furik
  class Cli < Thor
    def self.exit_on_failure?
      true
    end

    desc 'pulls', 'show pull requests'
    method_option :start_date, type: :string, aliases: '-s'
    method_option :end_date, type: :string, aliases: '-e'
    def pulls
      start_date = Date.parse(options[:start_date]) if options[:start_date]
      end_date = Date.parse(options[:end_date]) if options[:end_date]

      puts "Pull Requests#{" (#{start_date}...#{end_date})" if start_date && end_date}"
      puts '-'
      puts ''

      Furik.pull_requests do |repo, issues|
        if issues && !issues.empty?
          string_issues = issues.each.with_object('') do |issue, memo|
            date = issue.created_at.localtime.to_date

            next if start_date && date < start_date
            next if end_date && date > end_date

            memo << "- [#{issue.title}](#{issue.html_url}):"
            memo << " (#{issue.body.plain.cut})" if issue.body && !issue.body.empty?
            memo << " #{issue.created_at.localtime.to_date}\n"
          end

          unless string_issues == ''
            puts "### #{repo}"
            puts ''
            puts string_issues
            puts ''
          end
        end
      end
    end

    desc 'activity', 'show activity'
    method_option :since, type: :numeric, aliases: '-d', default: 0
    method_option :from, type: :string, aliases: '-f', default: Date.today.to_s
    method_option :to, type: :string, aliases: '-t', default: Date.today.to_s
    def activity
      from = Date.parse(options[:from])
      to   = Date.parse(options[:to])
      since = options[:since]

      diff = (to - from).to_i
      from -= since if diff.zero?
      puts "GitHub Activities"
      puts '-'
      puts ''

      Furik.events_with_grouping(from: from, to: to) do |repo, events|
        puts "### #{repo}"
        puts ''

        events.sort_by(&:type).reverse.each_with_object({ keys: [] }) do |event, memo|
          payload_type = event.type.gsub('Event', '').gsub(/.*Comment/, 'Comment').gsub('Issues', 'Issue').underscore
          payload = event.payload.send(:"#{payload_type}")
          type = payload_type.dup

          title = case event.type
          when 'IssueCommentEvent'
            "#{payload.body.plain.cut} (#{event.payload.issue.title})"
          when 'CommitCommentEvent'
            payload.body.plain.cut
          when 'IssuesEvent'
            type = "#{event.payload.action}_#{type}"
            payload.title.plain
          when 'PullRequestReviewCommentEvent'
            type = 'comment'
            if event.payload.pull_request.respond_to?(:title)
              "#{payload.body.plain.cut} (#{event.payload.pull_request.title})"
            else
              payload.body.plain.cut
            end
          else
            payload.title.plain
          end

          link = payload.html_url
          key = "#{type}-#{link}"

          next if memo[:keys].include?(key)
          memo[:keys] << key

          puts "- [#{type}](#{link}): #{title}"
        end

        Furik.reviews_by_repo(repo: repo, from: from, to: to) do |pulls|
          pulls.each do |pr_title, reviews|
            reviews.each { |r| puts "- [review](#{r.html_url}): #{pr_title} #{r.state}" }
          end
        end

        puts ''
      end
    end
  end
end

Furik::Cli.start
