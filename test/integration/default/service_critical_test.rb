# frozen_string_literal: true

#
# Run some checks that should all result as CRITICAL.
#

check = '/opt/sensu-plugins-ruby/embedded/bin/check-habitat-service-health.rb'

describe command("#{check} -s dummy-critical1.default") do
  its(:exit_status) { should eq(2) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      CRITICAL: dummy-critical1.default: stdout: ""; stderr: ""
      CheckHabitatServiceHealth CRITICAL: Results: 1 critical, 0 warning, 0 unknown, 0 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end

describe command("#{check} -s nonexistent") do
  its(:exit_status) { should eq(2) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      CRITICAL: nonexistent: stdout: ""; stderr: "Service is not running"
      CheckHabitatServiceHealth CRITICAL: Results: 1 critical, 0 warning, 0 unknown, 0 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end

describe command(check) do
  its(:exit_status) { should eq(2) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      UNKNOWN: dummy-unknown1.default: stdout: ""; stderr: ""
      WARNING: dummy-warning1.default: stdout: ""; stderr: ""
      WARNING: dummy-warning2.default: stdout: ""; stderr: ""
      CRITICAL: dummy-critical1.default: stdout: ""; stderr: ""
      CheckHabitatServiceHealth CRITICAL: Results: 1 critical, 2 warning, 1 unknown, 3 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end
