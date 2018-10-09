# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/sensu_plugins_habitat/version'

describe SensuPluginsHabitat::Version do
  %i[MAJOR MINOR PATCH].each do |v|
    describe "::#{v}" do
      it 'returns an integer' do
        expect(described_class.const_get(v)).to be_an_instance_of(Integer)
      end
    end
  end

  describe '::VER_STRING' do
    it 'returns a properly formatted version string' do
      expect(described_class::VER_STRING).to match(/^[0-9]+\.[0-9]+\.[0-9]+$/)
    end
  end
end
