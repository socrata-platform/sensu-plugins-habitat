# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/sensu_plugins_habitat/check/base'

describe SensuPluginsHabitat::Check::Base do
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

    context 'an overridden host' do
      let(:argv) { %w[-H 1.2.3.4] }

      it 'uses the expected config' do
        exp = {
          host: '1.2.3.4',
          port: 9631,
          protocol: 'http',
          insecure: false,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden port' do
      let(:argv) { %w[-P 4321] }

      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 4321,
          protocol: 'http',
          insecure: false,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden protocol' do
      let(:argv) { %w[-p https] }

      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 9631,
          protocol: 'https',
          insecure: false,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden insecure' do
      let(:argv) { %w[-i] }

      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 9631,
          protocol: 'http',
          insecure: true,
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden capath' do
      let(:argv) { %w[-c /path/to/file] }

      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 9631,
          protocol: 'http',
          insecure: false,
          capath: '/path/to/file',
          timeout: 5
        }
        expect(check.config).to eq(exp)
      end
    end

    context 'an overridden timeout' do
      let(:argv) { %w[-t 1] }

      it 'uses the expected config' do
        exp = {
          host: '127.0.0.1',
          port: 9631,
          protocol: 'http',
          insecure: false,
          timeout: 1
        }
        expect(check.config).to eq(exp)
      end
    end
  end

  describe '#run' do
    it 'exits 0 to satisfy SensuPlugin' do
      c = check
      expect(c).to receive(:exit).with(0)
      c.run
    end
  end

  describe '#hab_get' do
    let(:endpoint) { '/pants' }
    let(:res) { check.hab_get(endpoint) }

    context 'all default options' do
      it 'gets the expected URL' do
        expect(check).to receive(:get).with('http://127.0.0.1:9631/pants')
                                      .and_return('stub')
        expect(res).to eq('stub')
      end
    end

    context 'an overridden protocol' do
      let(:argv) { %w[-p https] }

      it 'gets the expected URL' do
        expect(check).to receive(:get).with('https://127.0.0.1:9631/pants')
                                      .and_return('stub')
        expect(res).to eq('stub')
      end
    end

    context 'an overridden host' do
      let(:argv) { %w[-H 1.2.3.4] }

      it 'gets the expected URL' do
        expect(check).to receive(:get).with('http://1.2.3.4:9631/pants')
                                      .and_return('stub')
        expect(res).to eq('stub')
      end
    end

    context 'an overridden port' do
      let(:argv) { %w[-P 5] }

      it 'gets the expected URL' do
        expect(check).to receive(:get).with('http://127.0.0.1:5/pants')
                                      .and_return('stub')
        expect(res).to eq('stub')
      end
    end
  end

  describe '#get' do
    let(:url) { 'http://1.2.3.4:5' }
    let(:res) { check.get(url) }

    before do
      allow(check).to receive(:http_params_for)
        .with(URI(url)).and_return('stub')
    end

    it 'returns the response for an HTTP 200' do
      resp = Net::HTTPOK.new(1, 2, 3)
      allow(Net::HTTP).to receive(:start)
        .with('stub').and_return(double(get: resp))
      expect(res).to eq(resp)
    end

    it 'recurses over an HTTP redirect' do
      resp = Net::HTTPRedirection.new(1, 2, 3)
      resp.header['location'] = 'http://anotherstub'
      allow(Net::HTTP).to receive(:start)
        .with('stub').and_return(double(get: resp))

      resp2 = Net::HTTPOK.new(1, 2, 3)
      allow(check).to receive(:http_params_for)
        .with(URI('http://anotherstub')).and_return('anotherstub')
      allow(Net::HTTP).to receive(:start)
        .with('anotherstub').and_return(double(get: resp2))

      expect(res).to eq(resp2)
    end

    it 'goes CRITICAL with a connection refused' do
      allow(Net::HTTP).to receive(:start)
        .with('stub').and_raise(Errno::ECONNREFUSED, 'pant')
      expect(check).to receive(:critical)
        .with('Connection to the supervisor API failed: Connection refused ' \
              '- pant')
        .and_return('stub')
      expect(res).to eq('stub')
    end

    it 'goes CRITICAL with a connection timeout' do
      allow(Net::HTTP).to receive(:start)
        .with('stub').and_raise(Net::OpenTimeout, 'pant')
      expect(check).to receive(:critical)
        .with('Connection to the supervisor API failed: pant')
        .and_return('stub')
      expect(res).to eq('stub')
    end
  end

  describe '#http_params' do
    let(:uri) { URI('http://1.2.3.4:5') }
    let(:res) { check.http_params_for(uri) }

    context 'all default options' do
      it 'returns the expected params' do
        exp = [
          '1.2.3.4',
          5,
          { use_ssl: false, open_timeout: 5, read_timeout: 5 }
        ]
        expect(res).to eq(exp)
      end
    end

    context 'an HTTPS URI' do
      let(:uri) { URI('https://1.2.3.4:5') }

      it 'returns the expected params' do
        exp = [
          '1.2.3.4',
          5,
          { use_ssl: true, open_timeout: 5, read_timeout: 5 }
        ]
        expect(res).to eq(exp)
      end
    end

    context 'an overridden timeout' do
      let(:argv) { %w[-t 1] }

      it 'returns the expected params' do
        exp = [
          '1.2.3.4',
          5,
          { use_ssl: false, open_timeout: 1, read_timeout: 1 }
        ]
        expect(res).to eq(exp)
      end
    end

    context 'an overridden SSL verification' do
      let(:argv) { %w[-i] }

      it 'returns the expected params' do
        exp = [
          '1.2.3.4',
          5,
          {
            use_ssl: false,
            open_timeout: 5,
            read_timeout: 5,
            verify_mode: OpenSSL::SSL::VERIFY_NONE
          }
        ]
        expect(res).to eq(exp)
      end
    end

    context 'an overridden CA path' do
      let(:argv) { %w[-c /a/file] }

      it 'returns the expected params' do
        exp = [
          '1.2.3.4',
          5,
          {
            use_ssl: false,
            open_timeout: 5,
            read_timeout: 5,
            ca_file: '/a/file'
          }
        ]
        expect(res).to eq(exp)
      end
    end
  end
end
