# frozen_string_literal: true

#
# Run some checks that should all result as OK.
#

check = '/opt/sensu/embedded/bin/check-habitat-service-health.rb'

describe command("#{check} -s dummy-ok1.default") do
  its(:exit_status) { should eq(0) }
  its(:stdout) do
    expected = 'CheckHabitatServiceHealth OK: Results: 0 critical, ' \
               "0 warning, 0 unknown, 1 ok\n"
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end

describe command("#{check} -s dummy-ok1.default,dummy-ok2.default," \
                 'dummy-ok3.default') do
  its(:exit_status) { should eq(0) }
  its(:stdout) do
    expected = 'CheckHabitatServiceHealth OK: Results: 0 critical, ' \
               "0 warning, 0 unknown, 3 ok\n"
    should eq(expected)
  end
  its(:stderr) { should be_empty }
end
