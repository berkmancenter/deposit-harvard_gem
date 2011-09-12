require File.dirname(__FILE__) + "/deposit/version"

# Deposit::Repositories.configure do
#   sword :harvard do
#     url "whatever"
#     credentials "things"
#   end
#
#   other_protocol :mit do
#     url "whatevs"
#     things "whatever"
#   end
# end

module Deposit
  require File.dirname(__FILE__) + "/deposit/sword_client"
end
