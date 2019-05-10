# frozen_string_literal: true

#
# Run some checks that should all result as UNKNOWN.
#

check = '/opt/sensu/embedded/bin/check-habitat-service-health.rb'

describe command("#{check} -s dummy-unknown1.default") do
  its(:exit_status) { should eq(3) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      UNKNOWN: dummy-unknown1.default: stdout: ""; stderr: ""
      CheckHabitatServiceHealth UNKNOWN: Results: 0 critical, 0 warning, 1 unknown, 0 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end
