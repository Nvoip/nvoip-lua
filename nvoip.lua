local https = require("ssl.https")
local ltn12 = require("ltn12")
local cjson = require("cjson.safe")

local function base64_encode(input)
  local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  return ((input:gsub(".", function(char)
    local byte = char:byte()
    local bits = ""
    for index = 8, 1, -1 do
      bits = bits .. ((byte % 2 ^ index - byte % 2 ^ (index - 1) > 0) and "1" or "0")
    end
    return bits
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(bits)
    if #bits < 6 then
      return ""
    end
    local value = 0
    for index = 1, 6 do
      if bits:sub(index, index) == "1" then
        value = value + 2 ^ (6 - index)
      end
    end
    return alphabet:sub(value + 1, value + 1)
  end) .. ({ "", "==", "=" })[#input % 3 + 1])
end

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
    base_url = (config.base_url or "https://api.nvoip.com.br/v2"):gsub("/+$", ""),
    oauth_client_id = config.oauth_client_id,
    oauth_client_secret = config.oauth_client_secret,
  }, self)
end

function Client.encode_basic_auth(client_id, client_secret)
  return base64_encode(client_id .. ":" .. client_secret)
end

function Client:_resolve_basic_auth()
  if self.oauth_client_id and self.oauth_client_id ~= "" and self.oauth_client_secret and self.oauth_client_secret ~= "" then
    return Client.encode_basic_auth(self.oauth_client_id, self.oauth_client_secret)
  end

  error("Missing OAuth client credentials. Configure oauth_client_id + oauth_client_secret.", 2)
end

function Client:create_access_token(numbersip, user_token)
  return self:_request("POST", "/oauth/token", {
    body = encode_query({
      username = numbersip,
      password = user_token,
      grant_type = "password",
    }),
    headers = {
      ["Authorization"] = "Basic " .. self:_resolve_basic_auth(),
      ["Content-Type"] = "application/x-www-form-urlencoded",
    },
  })
end

function Client:refresh_access_token(refresh_token)
  return self:_request("POST", "/oauth/token", {
    body = encode_query({
      grant_type = "refresh_token",
      refresh_token = refresh_token,
    }),
    headers = {
      ["Authorization"] = "Basic " .. self:_resolve_basic_auth(),
      ["Content-Type"] = "application/x-www-form-urlencoded",
    },
  })
end

function Client:get_balance(access_token)
  return self:_request("GET", "/balance", {
    headers = {
      ["Authorization"] = "Bearer " .. access_token,
    },
  })
end

function Client:send_sms(options)
  return self:_request("POST", "/sms", {
    access_token = options.access_token,
    napikey = options.napikey,
    json = {
      numberPhone = options.number_phone,
      message = options.message,
      flashSms = options.flash_sms or false,
    },
  })
end

function Client:create_call(caller, called, access_token)
  return self:_request("POST", "/calls/", {
    access_token = access_token,
    json = {
      caller = caller,
      called = called,
    },
  })
end

function Client:send_otp(options)
  local payload = {}
  if options.sms then
    payload.sms = options.sms
  end
  if options.voice then
    payload.voice = options.voice
  end
  if options.email then
    payload.email = options.email
  end

  return self:_request("POST", "/otp", {
    access_token = options.access_token,
    napikey = options.napikey,
    json = payload,
  })
end

function Client:check_otp(code, key)
  return self:_request("GET", "/check/otp?code=" .. urlencode(code) .. "&key=" .. urlencode(key), {})
end

function Client:list_whatsapp_templates(access_token)
  return self:_request("GET", "/wa/listTemplates", {
    headers = {
      ["Authorization"] = "Bearer " .. access_token,
    },
  })
end

function Client:send_whatsapp_template(options)
  local payload = {
    idTemplate = options.id_template,
    destination = options.destination,
    instance = options.instance,
    language = options.language,
  }

  if options.body_variables ~= nil then
    payload.bodyVariables = options.body_variables
  end
  if options.header_variables ~= nil then
    payload.headerVariables = options.header_variables
  end
  if options.to_flow ~= nil then
    payload.functions = {
      to_flow = options.to_flow,
    }
  end

  return self:_request("POST", "/wa/sendTemplates", {
    access_token = options.access_token,
    json = payload,
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
    protocol = "tlsv1_2",
  })

  local raw = table.concat(response_chunks)
  local decoded = cjson.decode(raw)
  local payload = decoded or { raw = raw }

  if not ok or (status_code and status_code >= 400) then
    error(("Nvoip request failed with status %s: %s"):format(tostring(status_code), raw), 2)
  end

  return payload
end

return {
  encode_basic_auth = Client.encode_basic_auth,
  new = function(config)
    return Client:new(config)
  end,
}
