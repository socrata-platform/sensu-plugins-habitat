# frozen_string_literal: true

require_relative 'spec_helper'
require_relative '../bin/check-habitat-service-health'

describe CheckHabitatServiceHealth do
  let(:argv) { %w[] }
  let(:check) { described_class.new(argv) }

  # Don't let Sensu::Plugin::CLI hijack RSpec with its `at_exit` block.
  after do
    described_class.class_variable_set(:@@autorun, false)
  end

  describe '#initialize' do
    context 'all default options' do
      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 9631,
          protocol: 'http',
          insecure: false,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden services' do
      let(:argv) { %w[-s service1.default,service2.default] }

      it 'uses the expected config' do
        exp = {
          services: 'service1.default,service2.default',
          host: '127.0.0.1',
          port: 9631,
          protocol: 'http',
          insecure: false,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end
  end

  describe '#run' do
    context 'all ok' do
      before do
        allow_any_instance_of(described_class).to receive(:summary_str)
          .and_return('all ok')
        allow_any_instance_of(described_class).to receive(:results_str)
          .and_return('')
        allow_any_instance_of(described_class).to receive(:results)
          .and_return(ok: %w[thing1 thing2],
                      warning: [],
                      critical: [],
                      unknown: [])
      end

      it 'returns OK' do
        c = check
        expect(c).to receive(:ok).with('all ok').and_return('ok')
        expect(c.run).to eq('ok')
      end
    end

    context 'some unknown services' do
      before do
        allow_any_instance_of(described_class).to receive(:summary_str)
          .and_return('some unknowns')
        allow_any_instance_of(described_class).to receive(:results_str)
          .and_return("UNKNOWN: mark\nUNKNOWN: tom\nUNKNOWN: travis")
        allow_any_instance_of(described_class).to receive(:results)
          .and_return(ok: [],
                      warning: [],
                      critical: [],
                      unknown: %w[mark tom travis])
      end

      it 'returns UNKNOWN' do
        c = check
        exp = <<-EXP.gsub(/^ +/, '').strip
          UNKNOWN: mark
          UNKNOWN: tom
          UNKNOWN: travis
        EXP
        expect(c).to receive(:puts).with(exp)
        expect(c).to receive(:unknown).with('some unknowns')
                                      .and_return('unknown')
        expect(c.run).to eq('unknown')
      end
    end

    context 'some warning services' do
      before do
        allow_any_instance_of(described_class).to receive(:summary_str)
          .and_return('some warnings')
        allow_any_instance_of(described_class).to receive(:results_str)
          .and_return('WARNING')
        allow_any_instance_of(described_class).to receive(:results)
          .and_return(ok: %w[thing1 thing2],
                      warning: %w[thing3],
                      critical: [],
                      unknown: [])
      end

      it 'returns WARNING' do
        c = check
        expect(c).to receive(:puts).with('WARNING')
        expect(c).to receive(:warning).with('some warnings')
                                      .and_return('warning')
        expect(c.run).to eq('warning')
      end
    end

    context 'some critical services' do
      before do
        allow_any_instance_of(described_class).to receive(:summary_str)
          .and_return('some criticals')
        allow_any_instance_of(described_class).to receive(:results_str)
          .and_return('CRITICAL')
        allow_any_instance_of(described_class).to receive(:results)
          .and_return(ok: %w[thing1 thing2],
                      warning: %w[thing3],
                      critical: %w[thing4 thing5],
                      unknown: [])
      end

      it 'returns CRITICAL' do
        c = check
        expect(c).to receive(:puts).with('CRITICAL')
        expect(c).to receive(:critical).with('some criticals')
                                       .and_return('critical')
        expect(c.run).to eq('critical')
      end
    end

    context 'a mix of statuses' do
      before do
        allow_any_instance_of(described_class).to receive(:summary_str)
          .and_return('Results: 2 critical, 1 warning, 1 unknown, 3 ok')
        allow_any_instance_of(described_class).to receive(:results_str)
          .and_return("UNKNOWN: thing1\nWARNING: thing2\nCRITICAL: thing3\n" \
                      'CRITICAL: thing4')
        allow_any_instance_of(described_class).to receive(:results)
          .and_return(ok: %w[thing5 thing6 thing7],
                      warning: %w[thing2],
                      critical: %w[thing3 thing4],
                      unknown: %w[thing1])
      end

      it 'returns CRITICAL' do
        c = check
        exp = <<-EXP.gsub(/^ +/, '').strip
          UNKNOWN: thing1
          WARNING: thing2
          CRITICAL: thing3
          CRITICAL: thing4
        EXP
        expect(c).to receive(:puts).with(exp)
        expect(c).to receive(:critical)
          .with('Results: 2 critical, 1 warning, 1 unknown, 3 ok')
          .and_return('critical')
        expect(c.run).to eq('critical')
      end
    end
  end

  describe '#results_str' do
    before do
      res = {
        ok: [
          's1.g1: stdout: "Y"; stderr: ""',
          's2.g1: stdout: "Y"; stderr: ""'
        ],
        warning: ['s3.g1: stdout: "N"; stderr: ""'],
        critical: ['s4.g1: stdout: "N"; stderr: "Uhoh"'],
        unknown: ['s5.g1: stdout: ""; stderr: "Que?"']
      }
      allow_any_instance_of(described_class).to receive(:results)
        .and_return(res)
    end

    it 'constructs a string of all the non-okay results' do
      exp = <<-EXP.gsub(/^ +/, '').strip
        UNKNOWN: s5.g1: stdout: ""; stderr: "Que?"
        WARNING: s3.g1: stdout: "N"; stderr: ""
        CRITICAL: s4.g1: stdout: "N"; stderr: "Uhoh"
      EXP
      expect(check.results_str).to eq(exp)
    end
  end

  describe '#summary_str' do
    before do
      res = {
        ok: [
          's1.g1: stdout: "Y"; stderr: ""',
          's2.g1: stdout: "Y"; stderr: ""'
        ],
        warning: ['s3.g1: stdout: "N"; stderr: ""'],
        critical: ['s4.g1: stdout: "N"; stderr: "Uhoh"'],
        unknown: ['s5.g1: stdout: ""; stderr: "Que?"']
      }
      allow_any_instance_of(described_class).to receive(:results)
        .and_return(res)
    end

    it 'constructs a final summary message' do
      exp = 'Results: 1 critical, 1 warning, 1 unknown, 2 ok'
      expect(check.summary_str).to eq(exp)
    end
  end

  describe '#results' do
    before do
      svcs = [
        { service: 's1.g1', status: 'OK', stdout: "Y\n", stderr: '' },
        { service: 's2.g1', status: 'OK', stdout: "Y\n", stderr: '' },
        { service: 's3.g1', status: 'WARNING', stdout: "N\n", stderr: '' },
        {
          service: 's4.g1',
          status: 'CRITICAL',
          stdout: "N\n",
          stderr: "Uhoh\n"
        },
        { service: 's5.g1', status: 'UNKNOWN', stdout: '', stderr: '' }
      ]
      allow_any_instance_of(described_class).to receive(:health_statuses)
        .and_return(svcs)
    end

    it 'returns the service result strings grouped by result' do
      exp = {
        ok: [
          's1.g1: stdout: "Y"; stderr: ""',
          's2.g1: stdout: "Y"; stderr: ""'
        ],
        warning: ['s3.g1: stdout: "N"; stderr: ""'],
        critical: ['s4.g1: stdout: "N"; stderr: "Uhoh"'],
        unknown: ['s5.g1: stdout: ""; stderr: ""']
      }
      expect(check.results).to eq(exp)
    end
  end

  describe '#health_statuses' do
    before do
      allow_any_instance_of(described_class).to receive(:services)
        .and_return(%w[svc1.default svc2.default])
      allow_any_instance_of(described_class).to receive(:health_of_service)
        .with('svc1.default')
        .and_return(status: 'OK', stdout: 'Okay', stderr: '')
      allow_any_instance_of(described_class).to receive(:health_of_service)
        .with('svc2.default')
        .and_return(status: 'CRITICAL', stdout: '', stderr: 'Bad!')
    end

    it 'saves and returns an array of health check data' do
      c = check
      exp = [
        {
          service: 'svc1.default',
          status: 'OK',
          stdout: 'Okay',
          stderr: ''
        },
        {
          service: 'svc2.default',
          status: 'CRITICAL',
          stdout: '',
          stderr: 'Bad!'
        }
      ]
      expect(c.health_statuses).to eq(exp)
      expect(c.instance_variable_get(:@health_statuses)).to eq(exp)
    end
  end

  describe '#health_of_service' do
    before do
      resp = double('Net::HTTPOK',
                    code: 200,
                    body: '{"status":"OK","stdout":"Yay!","stderr":"?"}')
      allow(resp).to receive(:is_a?).with(Net::HTTPNotFound).and_return(false)
      allow_any_instance_of(described_class).to receive(:hab_get)
        .with('/services/svc1/default/health').and_return(resp)

      resp2 = double('Net::HTTPNotFound', code: 404)
      allow(resp2).to receive(:is_a?).with(Net::HTTPNotFound).and_return(true)
      allow_any_instance_of(described_class).to receive(:hab_get)
        .with('/services/bad/default/health').and_return(resp2)
    end

    context 'an OK service' do
      let(:service) { 'svc1.default' }

      it 'returns the health status from the API' do
        exp = { status: 'OK', stdout: 'Yay!', stderr: '?' }
        expect(check.health_of_service(service)).to eq(exp)
      end
    end

    context 'a not running service' do
      let(:service) { 'bad.default' }

      it 'returns a critical status' do
        exp = {
          status: 'CRITICAL',
          stdout: '',
          stderr: 'Service is not running'
        }
        expect(check.health_of_service(service)).to eq(exp)
      end
    end
  end

  describe '#services' do
    before do
      allow_any_instance_of(described_class).to receive(:hab_get_services)
        .and_return(%w[s2.default s1.default])
    end

    context 'default services fetched from the API' do
      it 'saves and returns the expected list of services' do
        c = check
        exp = %w[s1.default s2.default]
        expect(c.services).to eq(exp)
        expect(c.instance_variable_get(:@services)).to eq(exp)
      end
    end

    context 'services provided at the command line' do
      let(:argv) { %w[-s s4.default,s3.default] }

      it 'saves and returns the expected list of services' do
        c = check
        exp = %w[s3.default s4.default]
        expect(c.services).to eq(exp)
        expect(c.instance_variable_get(:@services)).to eq(exp)
      end
    end
  end

  describe '#hab_get_services' do
    context 'an HTTP 200 OK' do
      before do
        body = '[{"smoke_check":"Pending","service_group":"s1.default"},' \
               '{"smoke_check":"Pending","service_group":"s2.default"},' \
               '{"smoke_check":"Pending","service_group":"s3.default"},' \
               '{"smoke_check":"Pending","service_group":"s4.default"}]'
        resp = double('Net::HTTPOK', body: body)
        allow(resp).to receive(:is_a?).with(Net::HTTPOK).and_return(true)
        allow_any_instance_of(described_class).to receive(:hab_get)
          .with('/services').and_return(resp)
      end

      it 'returns the expected list of services' do
        exp = %w[s1.default s2.default s3.default s4.default]
        expect(check.hab_get_services).to eq(exp)
      end
    end

    context 'an HTTP 500 internal server error' do
      before do
        resp = double('Net::HTTPInternalServerError', code: 500)
        allow(resp).to receive(:is_a?).with(Net::HTTPOK).and_return(false)
        allow_any_instance_of(described_class).to receive(:hab_get)
          .with('/services').and_return(resp)
      end

      it 'returns CRITICAL' do
        c = check
        expect(c).to receive(:critical)
          .with('Failed to fetch /services from the supervisor API: 500')
          .and_return('critical')
        expect(c.hab_get_services).to eq('critical')
      end
    end
  end
end
