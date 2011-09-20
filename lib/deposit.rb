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

# then you can Deposit.deposit(:mit, hash_with_info) or Deposit.deposit_all.  that way we could make it asynchronous easier 

module Deposit
  require File.dirname(__FILE__) + "/deposit/sword_client"
end
