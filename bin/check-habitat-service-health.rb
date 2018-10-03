#!/usr/bin/env ruby
# frozen_string_literal: false

#
#   check-habitat-service-health.rb
#
# DESCRIPTION:
#   This check queries a Habitat supervisor's API to monitor the health status
#   of its servies.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# Query a Habitat supervisor on 127.0.0.1:9631 and check all running services:
#
#   check-habitat-service-health.rb
#
# Query a Habitat supervisor on a non-default host and/or port:
#
#
#   > check-habitat-service-health.rb -H 192.168.0.4
#   > check-habitat-service-health.rb --host 192.168.0.4
#   > check-habitat-service-health.rb -P 4242
#   > check-habitat-service-health.rb --port 4242
#   > check-habitat-service-health.rb -H 1.2.3.4 -P 5678
#
# Check a specific set of services instead of all running ones:
#
#   > check-habitat-service-health.rb -s svc1.default,svc2.default
#   > check-habitat-service-health.rb --services svc1.default,svc2.default
#
# NOTES:
#
# LICENSE:
#   Copyright 2018, Tyler Technologies <sysadmin@socrata.com>
#
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'net/http'
require_relative '../lib/sensu_plugins_habitat/check/base'

#
# Check Habitat service health.
#
class CheckHabitatServiceHealth < SensuPluginsHabitat::Check::Base
  option :services,
         short: '-s COMMA,SEPARATED,SERVICE,LIST',
         long: '--services COMMA,SEPARATED,SERVICE,LIST',
         description: 'Check specific services instead of all running ones'

  #
  # - If any monitored services are not OK, print their status strings.
  # - Print a summary line tallying the number of services in each status.
  # - Exit with the worst status of the services checked; i.e., if at least one
  #   service is currently CRITICAL, exit as CRITICAL.
  #
  def run
    puts results_str unless results_str.empty?
    stat = %i[critical warning unknown].find { |s| !results[s].empty? } || :ok
    send(stat, summary_str)
  end

  #
  # Construct a check result body that lists the output of every service that
  # isn't in an OK state, to be joined with the summary string for the complete
  # check output.
  #
  # @return [String] a long string of all the non-ok service statuses
  #
  def results_str
    %i[unknown warning critical].map do |stat|
      results[stat].map { |r| "#{stat.upcase}: #{r}" }
    end.flatten.compact.join("\n")
  end

  #
  # Construct a summary line to display at the end of the check output,
  # tallying how many services there are of each result status.
  #
  # @return [String] a summary status of all the service statuses
  #
  def summary_str
    "Results: #{results[:critical].size} critical, " \
      "#{results[:warning].size} warning, " \
      "#{results[:unknown].size} unknown, #{results[:ok].size} ok"
  end

  #
  # Turn every health check result into a status string and group them by
  # result status, structured as:
  #
  #   {
  #     ok: [
  #       'service_name.service_group: stdout: "output"; stderr: "output"'
  #     ],
  #     warning: [],
  #     critical: [],
  #     unknown: []
  #   }
  #
  # @return [Hash] the health check data organized by status
  #
  def results
    @results ||= %i[unknown ok warning critical]
                 .each_with_object({}) do |stat, hsh|
      data = health_statuses.select { |h| h[:status] == stat.to_s.upcase }
      hsh[stat] = data.map do |d|
        "#{d[:service]}: stdout: \"#{d[:stdout].strip}\"; " \
          "stderr: \"#{d[:stderr].strip}\""
      end
    end
  end

  #
  # Fetch, save, and return the health check data for every service that we're
  # supposed to be monitoring, structued as:
  #
  #   [
  #     {
  #       service: 'service_name.service_group',
  #       status: 'health_check_status',
  #       stdout: 'health_check_stdout',
  #       stderr: 'health_check_stderr'
  #     }
  #   ]
  #
  # Note that empty outputs in stdout or stderr are returned as empty strings,
  # not nil/null values.
  #
  # @return [Array<Hash>] an array of service health check data
  #
  def health_statuses
    @health_statuses ||= services.map do |svc|
      { service: svc }.merge(health_of_service(svc))
    end
  end

  #
  # Fetch and return the health of a given service from the supervisor API. If
  # a service is not found (404, not running at all), consider it a critical
  # status.
  #
  # The supervisor API returns the following HTTP responses for check results:
  #
  # * OK => 200 => Net::HTTPOK
  # * WARNING => 200 => Net::HTTPOK
  # * CRITICAL => 503 => Net::HTTPServiceUnavailable
  # * UNKNOWN => 500 => Net::HTTPInternalServerError
  # * Not running => 404 => Net::HTTPNotFound
  #
  # @param service [String] 'svc_name.svc_group'
  # @return [Hash] the parsed JSON from that service's /health endpoint
  #
  def health_of_service(service)
    resp = hab_get("/services/#{service.tr('.', '/')}/health")

    if resp.is_a?(Net::HTTPNotFound)
      { status: 'CRITICAL', stdout: '', stderr: 'Service is not running' }
    else
      JSON.parse(resp.body, symbolize_names: true)
    end
  end

  #
  # Return an array of the services we should be monitoring, either fed in via
  # config[:services] or fetched from the supervisor API.

  #
  # @return [Array<String>] an array of the services to be monitored
  #
  def services
    @services ||= if config[:services]
                    config[:services].split(',')
                  else
                    hab_get_services
                  end.sort
  end

  # Fetch and parse the /services endpoint from the supervisor API. If it can't
  # be fetched for whatever reason, go CRITICAL immediately.
  #
  # @return [Array<String>] an array of service names.groups
  # @raise [CRITICAL] if the services can't be fetched
  #
  def hab_get_services
    resp = hab_get('/services')

    if resp.is_a?(Net::HTTPOK)
      JSON.parse(resp.body).map { |svc| svc['service_group'] }
    else
      critical('Failed to fetch /services from the supervisor ' \
               "API: #{resp.code}")
    end
  end
end
