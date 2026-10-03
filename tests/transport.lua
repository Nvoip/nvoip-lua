local requests = {}
package.loaded["ssl.https"] = { request = function(options) requests[#requests + 1] = options; return 1, 200 end }
local last_body
package.loaded["ltn12"] = { source = { string = function(value) last_body = value; return value end }, sink = { table = function() return function() end end } }
package.loaded["cjson.safe"] = { encode = function() return "{}" end, decode = function() return {} end }
local nvoip = dofile("nvoip.lua")
local client = nvoip.new({ base_url = "https://local/v3", oauth_client_id = "id +", oauth_client_secret = "secret:/" })
client:create_access_token(); client:get_balance("token"); client:check_otp("token", "a b", "key/1")
assert(requests[1].url == "https://api.nvoip.com.br/auth/oauth2/token", requests[1].url)
assert(last_body == "grant_type=client_credentials")
assert(requests[1].headers.Authorization:match("^Basic "))
assert(requests[2].headers.Authorization == "Bearer token")
assert(requests[3].headers.Authorization == "Bearer token")
