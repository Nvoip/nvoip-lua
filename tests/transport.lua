local requests = {}
local tls_parameters = {}
local last_body
local connected_host
local forced_dns_names
local forced_ip_addresses
local omit_subject_alt_name

local function certificate_for(host)
  return {
    extensions = function()
      if omit_subject_alt_name then
        return {}
      end
      return {
        ["2.5.29.17"] = {
          dNSName = forced_dns_names or { host },
          iPAddress = forced_ip_addresses or {},
        },
      }
    end,
  }
end

package.loaded["ssl.https"] = {
  tcp = function(parameters)
    tls_parameters[#tls_parameters + 1] = parameters
    return function()
      local connection = {}
      function connection:connect(host)
        connected_host = host
        return 1
      end
      function connection:getpeercertificate()
        return certificate_for(connected_host)
      end
      function connection:close()
        return 1
      end
      return connection
    end
  end,
}

package.loaded["socket.http"] = {
  request = function(options)
    local host = options.url:match("^https://([^/:]+)")
    local connection = options.create()
    connection:connect(host, 443)
    requests[#requests + 1] = options
    if options.sink then
      options.sink("{}")
    end
    return 1, 200
  end,
}

package.loaded["ltn12"] = {
  source = {
    string = function(value)
      last_body = value
      return value
    end,
  },
  sink = {
    table = function(target)
      return function(chunk)
        if chunk then
          target[#target + 1] = chunk
        end
        return 1
      end
    end,
  },
}

package.loaded["cjson.safe"] = {
  encode = function() return "{}" end,
  decode = function() return {} end,
}

local nvoip = dofile("nvoip.lua")
local client = nvoip.new({
  base_url = "https://local/v3",
  oauth_client_id = "id +",
  oauth_client_secret = "secret:/",
  cafile = "README.md",
})

client:create_access_token()
client:get_balance("token")
client:check_otp("token", "a b", "key/1")

assert(requests[1].url == "https://api.nvoip.com.br/auth/oauth2/token", requests[1].url)
assert(last_body == "grant_type=client_credentials")
assert(requests[1].headers.Authorization:match("^Basic "))
assert(requests[2].headers.Authorization == "Bearer token")
assert(requests[3].headers.Authorization == "Bearer token")
for _, parameters in ipairs(tls_parameters) do
  assert(parameters.verify == "peer")
  assert(parameters.cafile == "README.md")
  assert(parameters.protocol == "tlsv1_2")
end

forced_dns_names = { "wrong.example.test" }
local before_mismatch = #requests
local mismatch_ok, mismatch_error = pcall(function()
  client:get_balance("token")
end)
assert(not mismatch_ok)
assert(tostring(mismatch_error):match("TLS hostname verification failed"), tostring(mismatch_error))
assert(#requests == before_mismatch, "HTTP request must not be sent after a hostname mismatch")

local insecure_client = nvoip.new({ base_url = "http://local/v3", cafile = "README.md" })
local insecure_ok, insecure_error = pcall(function()
  insecure_client:get_balance("token")
end)
assert(not insecure_ok)
assert(tostring(insecure_error):match("only permits HTTPS"), tostring(insecure_error))

forced_dns_names = nil
forced_ip_addresses = { "127.0.0.1" }
local ip_client = nvoip.new({ base_url = "https://127.0.0.1/v3", cafile = "README.md" })
ip_client:get_balance("token")

forced_ip_addresses = nil
forced_dns_names = { "*.example.test" }
local wildcard_client = nvoip.new({ base_url = "https://api.example.test/v3", cafile = "README.md" })
wildcard_client:get_balance("token")

local deep_wildcard_client = nvoip.new({ base_url = "https://deep.api.example.test/v3", cafile = "README.md" })
local deep_ok, deep_error = pcall(function()
  deep_wildcard_client:get_balance("token")
end)
assert(not deep_ok)
assert(tostring(deep_error):match("TLS hostname verification failed"), tostring(deep_error))

forced_dns_names = { "local\0.attacker.example" }
local nul_ok, nul_error = pcall(function()
  client:get_balance("token")
end)
assert(not nul_ok)
assert(tostring(nul_error):match("TLS hostname verification failed"), tostring(nul_error))

forced_dns_names = nil
omit_subject_alt_name = true
local no_san_ok, no_san_error = pcall(function()
  client:get_balance("token")
end)
assert(not no_san_ok)
assert(tostring(no_san_error):match("no subjectAltName"), tostring(no_san_error))
