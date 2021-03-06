# frozen_string_literal: true

require 'octokit'
require_relative 'furik/core_ext/string.rb'
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
  end
end
