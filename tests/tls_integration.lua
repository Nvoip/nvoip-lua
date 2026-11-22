local mode, host, port, cafile, expected_error = ...
assert(mode and host and port and cafile, "usage: tls_integration.lua <success|failure> <host> <port> <cafile>")

package.path = "./?.lua;" .. package.path
local nvoip = require("nvoip")
local client = nvoip.new({
  base_url = "https://" .. host .. ":" .. port,
  cafile = cafile,
})

local ok, result = pcall(function()
  return client:get_balance("synthetic-test-token")
end)

if mode == "success" then
  assert(ok, tostring(result))
else
  assert(not ok, "TLS request unexpectedly succeeded")
  if expected_error then
    assert(tostring(result):find(expected_error, 1, true), tostring(result))
  end
end

