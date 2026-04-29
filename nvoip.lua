local https = require("ssl.https")
local ltn12 = require("ltn12")
local cjson = require("cjson.safe")

local BASIC_AUTH = "TnZvaXBBcGlWMjpUblp2YVhCQmNHbFdNakl3TWpFPQ=="

local function urlencode(value)
  return tostring(value):gsub("([^%w%-_%.~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

local function encode_query(query)
  local parts = {}
  for key, value in pairs(query) do
    parts[#parts + 1] = urlencode(key) .. "=" .. urlencode(value)
  end
  return table.concat(parts, "&")
end

local Client = {}
Client.__index = Client

function Client:new(config)
  config = config or {}
  return setmetatable({
    base_url = (config.base_url or "https://api.nvoip.com.br/v2"):gsub("/+$", "")
  }, self)
end

function Client:create_access_token(numbersip, user_token)
  return self:_request("POST", "/oauth/token", {
    body = encode_query({
      username = numbersip,
      password = user_token,
      grant_type = "password"
    }),
    headers = {
      ["Authorization"] = "Basic " .. BASIC_AUTH,
      ["Content-Type"] = "application/x-www-form-urlencoded"
    }
  })
end

function Client:get_balance(access_token)
  return self:_request("GET", "/balance", {
    headers = {
      ["Authorization"] = "Bearer " .. access_token
    }
  })
end

function Client:send_sms(options)
  return self:_request("POST", "/sms", {
    access_token = options.access_token,
    napikey = options.napikey,
    json = {
      numberPhone = options.number_phone,
      message = options.message,
      flashSms = options.flash_sms or false
    }
  })
end

function Client:_request(method, path, options)
  options = options or {}
  local url = self.base_url .. path
  if options.napikey then
    local separator = string.find(url, "?", 1, true) and "&" or "?"
    url = url .. separator .. encode_query({ napikey = options.napikey })
  end

  local response_chunks = {}
  local body = options.body
  local headers = options.headers or {}

  if options.access_token then
    headers["Authorization"] = "Bearer " .. options.access_token
  end

  if options.json then
    body = cjson.encode(options.json)
    headers["Content-Type"] = "application/json"
  end

  if body then
    headers["Content-Length"] = tostring(#body)
  end

  local ok, status_code = https.request({
    url = url,
    method = method,
    headers = headers,
    source = body and ltn12.source.string(body) or nil,
    sink = ltn12.sink.table(response_chunks),
    protocol = "tlsv1_2"
  })

  local raw = table.concat(response_chunks)
  local decoded = cjson.decode(raw)
  local payload = decoded or { raw = raw }

  if not ok or (status_code and status_code >= 400) then
    error(("Nvoip request failed with status %s"):format(tostring(status_code)), 2)
  end

  return payload
end

return {
  new = function(config)
    return Client:new(config)
  end
}
