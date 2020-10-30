# frozen_string_literal: true

require_relative '../furik.rb'
require 'thor'

module Furik
  class Cli < Thor
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
      puts "## GitHub Activities"

      Furik.events_with_grouping(from: from, to: to) do |repo, events|
        puts ''
        puts "### #{repo}"

        events.sort_by { |e| [e.owner.type, e.owner.number, e.occurred_at] }
              .each_with_object({ keys: [], recent_type: nil, owner: nil }) do |event, processed|
          next if processed[:keys].include?(event.key)

          processed[:keys] << event.key

          if event.owner.html_url != processed[:owner]
            puts ''
            puts "**[##{event.owner.number}](#{event.owner.html_url}) #{event.owner.title.strip}**"
            processed[:owner] = event.owner.html_url
          end

          puts event.summarize
        end
      end
    end
  end
end
