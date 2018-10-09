# frozen_string_literal: true

#
# Run some checks that should all result as WARNING.
#

check = '/opt/sensu/embedded/bin/check-habitat-service-health.rb'

describe command("#{check} -s dummy-warning1.default") do
  its(:exit_status) { should eq(1) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      WARNING: dummy-warning1.default: stdout: "Everything is mediocre"; stderr: ""
      CheckHabitatServiceHealth WARNING: Results: 0 critical, 1 warning, 0 unknown, 0 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end

describe command("#{check} -s dummy-warning1.default,dummy-warning2.default") do
  its(:exit_status) { should eq(1) }
  its(:stdout) do
    expected = <<-EXP.gsub(/^ +/, '')
      WARNING: dummy-warning1.default: stdout: "Everything is mediocre"; stderr: ""
      WARNING: dummy-warning2.default: stdout: "Everything is mediocre"; stderr: ""
      CheckHabitatServiceHealth WARNING: Results: 0 critical, 2 warning, 0 unknown, 0 ok
    EXP
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end
