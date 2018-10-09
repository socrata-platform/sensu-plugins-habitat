# frozen_string_literal: false

#
#   sensu_plugins_habitat/check/base.rb
#
# DESCRIPTION:
#   This class defines some of the common config options and helper methods for
#   Habitat plugins to use.
#
# OUTPUT:
#   N/A
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   Import this file and create subclasses of the included plugin class:
#
#     require 'sensu_plugins_habitat/check/base'
#     class CheckHabitatTest < SensuPluginsHabitat::Check::Base
#       ...
#
# NOTES:
#
# LICENSE:
#   Copyright 2018, Tyler Technologies <sysadmin@socrata.com>
#
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'json'
require 'net/http'
require 'openssl'
require 'sensu-plugin/check/cli'
require 'uri'

module SensuPluginsHabitat
  #
  # Habitat shared base plugin.
  #
  class Check
    # A base class with some common options that the actual plugins can inherit
    # from.
    class Base < Sensu::Plugin::Check::CLI
      option :host,
             short: '-H HOST',
             long: '--host HOST',
             description: 'Host the Habitat supervisor is listening on on',
             default: '127.0.0.1'

      option :port,
             short: '-P PORT',
             long: '--port PORT',
             description: 'Port the Habitat supervisor is listening on',
             proc: proc(&:to_i),
             default: 9631

      option :protocol,
             short: '-p PROTOCOL',
             long: '--protocol PROTOCOL',
             description: 'Switch to HTTPS if supervisor is SSL-ified',
             default: 'http'

      option :insecure,
             description: 'Set this flag to disable SSL verification',
             short: '-i',
             long: '--insecure',
             boolean: true,
             default: false

      option :capath,
             description: 'Absolute path to an alternative CA file',
             short: '-c CAPATH',
             long: '--capath CAPATH'

      option :timeout,
             description: 'Connection will time out after this many seconds',
             short: '-t TIMEOUT_IN_SECONDS',
             long: '--timeout TIMEOUT_IN_SECONDS',
             proc: proc(&:to_i),
             default: 5

      #
      # This should never be run, but Sensu complains if we don't define a run
      # method with an exit.
      #
      def run
        exit 0
      end

      #
      # Fetch and return a given endpoint from the Habitat supervisor API.
      #
      # @param endpoint [String] an API endpoint
      # @return [Net::HTTPResponse]
      #
      def hab_get(endpoint)
        server = "#{config[:protocol]}://#{config[:host]}:#{config[:port]}"
        get(File.join(server, endpoint))
      end

      #
      # Use net/http to do a GET on a URL and return the response object. If
      # the connection is refused or times out, consider it an automatic
      # CRITICAL, since the check presumably won't be able to proceed.
      #
      # @param url [String] the full URL to GET
      # @return [Net::HTTPResponse] the HTTP response object for processing
      # raise [CRITICAL] if the connection fails
      #
      def get(url)
        uri = URI(url)

        resp = Net::HTTP.start(*http_params_for(uri)).get(uri)

        resp.is_a?(Net::HTTPRedirection) ? get(resp.header['location']) : resp
      rescue Errno::ECONNREFUSED, Net::OpenTimeout => e
        critical("Connection to the supervisor API failed: #{e.message}")
      end

      #
      # Assemble the array of params for Net::HTTP.start, according to the
      # check config and URI object being retrieved.
      #
      # @param uri [URI] the URI object being fetched
      # @return [Array] the array of params for Net::HTTP.start
      #
      def http_params_for(uri)
        conn_opts = {
          use_ssl: uri.scheme == 'https',
          open_timeout: config[:timeout],
          read_timeout: config[:timeout],
          verify_mode: (OpenSSL::SSL::VERIFY_NONE if config[:insecure]),
          ca_file: config[:capath]
        }.compact

        [uri.host, uri.port, conn_opts]
      end
    end
  end
end
