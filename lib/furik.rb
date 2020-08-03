require 'octokit'
require_relative 'furik/core_ext/string.rb'
require_relative 'furik/pull_requests.rb'
require_relative 'furik/reviews.rb'
require_relative 'furik/events.rb'
require_relative 'furik/version.rb'

module Furik
  class << self
    def gh_client
      Octokit::Client.new(auto_paginate: true, per_page: 100, netrc: true)
    end

    def events_with_grouping(from: nil, to: nil, &block)
      events = []

      gh_events = Events.new(gh_client).events_with_grouping(from, to, &block)
      events.concat gh_events if gh_events.is_a?(Array)

      events
    end

    def reviews_by_repo(repo:, from: nil, to: nil, &block)
      Reviews.new(gh_client).reviews_by_repo(repo, from, to, &block)
    end

    def pull_requests(&block)
      pulls = []

      gh_pulls = PullRequests.new(gh_client).all(&block)
      pulls.concat gh_pulls if gh_pulls.is_a?(Array)

      pulls
    end
  end
end
