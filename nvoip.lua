local https = require("ssl.https")
local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson.safe")

local DEFAULT_CA_FILES = {
  "/etc/ssl/cert.pem",
  "/etc/ssl/certs/ca-certificates.crt",
  "/etc/pki/tls/certs/ca-bundle.crt",
  "/etc/ssl/ca-bundle.pem",
  "/usr/local/share/certs/ca-root-nss.crt",
  "/opt/homebrew/etc/ca-certificates/cert.pem",
  "/usr/local/etc/ca-certificates/cert.pem",
}

local function readable_file(path)
  if not path or path == "" then
    return false
  end
  local file = io.open(path, "rb")
  if not file then
    return false
  end
  file:close()
  return true
end

local function resolve_ca_locations(cafile, capath)
  local configured_cafile = cafile
  local configured_capath = capath
  if not configured_cafile or configured_cafile == "" then
    configured_cafile = os.getenv("SSL_CERT_FILE")
  end
  if not configured_capath or configured_capath == "" then
    configured_capath = os.getenv("SSL_CERT_DIR")
  end

  if configured_cafile and configured_cafile ~= "" then
    if not readable_file(configured_cafile) then
      error("TLS CA file is not readable: " .. configured_cafile, 3)
    end
    return configured_cafile, configured_capath
  end

  for _, candidate in ipairs(DEFAULT_CA_FILES) do
    if readable_file(candidate) then
      return candidate, configured_capath
    end
  end

  if configured_capath and configured_capath ~= "" then
    return nil, configured_capath
  end

  error("No TLS CA trust store found. Configure cafile/capath or SSL_CERT_FILE/SSL_CERT_DIR.", 3)
end

local function normalized_hostname(value)
  local hostname = string.lower(tostring(value or ""))
  return (hostname:gsub("%.$", ""))
end

local function is_ip_address(hostname)
  if hostname:find(":", 1, true) then
    return true
  end

  local parts = { hostname:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$") }
  if #parts ~= 4 then
    return false
  end
  for _, part in ipairs(parts) do
    if tonumber(part) > 255 then
      return false
    end
  end
  return true
end

local function dns_name_matches(pattern, hostname)
  pattern = normalized_hostname(pattern)
  hostname = normalized_hostname(hostname)
  if pattern:find("%z") or hostname:find("%z") then
    return false
  end
  if pattern == hostname then
    return true
  end
  local wildcard_suffix = pattern:sub(3)
  if pattern:sub(1, 2) ~= "*."
      or wildcard_suffix:find("*", 1, true)
      or not wildcard_suffix:find(".", 1, true) then
    return false
  end

  local suffix = pattern:sub(2)
  if hostname:sub(-#suffix) ~= suffix then
    return false
  end
  local leftmost = hostname:sub(1, #hostname - #suffix)
  return leftmost ~= "" and not leftmost:find(".", 1, true)
end

local function certificate_matches_hostname(certificate, hostname)
  if not certificate or type(certificate.extensions) ~= "function" then
    return false, "peer certificate does not expose subjectAltName"
  end

  local ok, extensions = pcall(certificate.extensions, certificate)
  local subject_alt_name = ok and extensions and extensions["2.5.29.17"]
  if not subject_alt_name then
    return false, "peer certificate has no subjectAltName"
  end

  hostname = normalized_hostname(hostname)
  if is_ip_address(hostname) then
    for _, address in ipairs(subject_alt_name.iPAddress or {}) do
      if normalized_hostname(address) == hostname then
        return true
      end
    end
    return false, "IP address is not present in subjectAltName"
  end

  for _, dns_name in ipairs(subject_alt_name.dNSName or {}) do
    if dns_name_matches(dns_name, hostname) then
      return true
    end
  end
  return false, "DNS name is not present in subjectAltName"
end

local function verified_tcp(params)
  local create_tls_connection = https.tcp(params)
  return function()
    local connection = create_tls_connection()
    local connect = connection.connect
    function connection:connect(host, port)
      local connected, connection_error = connect(self, host, port)
      if not connected then
        return connected, connection_error
      end

      local certificate = self:getpeercertificate()
      local matches, reason = certificate_matches_hostname(certificate, host)
      if not matches then
        pcall(function() self:close() end)
        error("TLS hostname verification failed for " .. tostring(host) .. ": " .. reason, 0)
      end
      return 1
    end
    return connection
  end
end

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
    base_url = (config.base_url or "https://api.nvoip.com.br/v3"):gsub("/+$", ""),
    oauth_client_id = config.oauth_client_id,
    oauth_client_secret = config.oauth_client_secret,
    cafile = config.cafile,
    capath = config.capath,
  }, self)
end

function Client.encode_basic_auth(client_id, client_secret)
  return base64_encode(urlencode(client_id) .. ":" .. urlencode(client_secret))
end

function Client:_resolve_basic_auth()
  if self.oauth_client_id and self.oauth_client_id ~= "" and self.oauth_client_secret and self.oauth_client_secret ~= "" then
    return Client.encode_basic_auth(self.oauth_client_id, self.oauth_client_secret)
  end

  error("Missing OAuth client credentials. Configure oauth_client_id + oauth_client_secret.", 2)
end

function Client:create_access_token()
  return self:_request("POST", "https://api.nvoip.com.br/auth/oauth2/token", {
    body = encode_query({
      grant_type = "client_credentials",
    }),
    headers = {
      ["Authorization"] = "Basic " .. self:_resolve_basic_auth(),
      ["Content-Type"] = "application/x-www-form-urlencoded",
    },
  })
end

function Client:refresh_access_token(refresh_token)
  return self:_request("POST", "https://api.nvoip.com.br/auth/oauth2/token", {
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
    json = payload,
  })
end

function Client:check_otp(access_token, code, key)
  return self:_request("GET", "/check/otp?code=" .. urlencode(code) .. "&key=" .. urlencode(key), { access_token = access_token })
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
    instance = options.instance,
    language = options.language,
  }
  local recipient = options.recipient
  if recipient ~= nil then
    local recipient_type = string.lower(recipient.type or "")
    local recipient_value = recipient.value or ""
    if recipient_type ~= "phone" and recipient_type ~= "bsuid" and recipient_type ~= "parent_bsuid" then
      error("recipient.type must be phone, bsuid or parent_bsuid", 2)
    end
    if recipient_value == "" or string.sub(recipient_value, 1, 1) == "@" then
      error("recipient.value is required and @username is not accepted", 2)
    end
    local recipient_digits = string.gsub(recipient_value, "^%+", "")
    if recipient_type == "phone"
        and (not string.match(recipient_digits, "^%d+$") or #recipient_digits < 8 or #recipient_digits > 20) then
      error("a phone recipient must contain only an optional leading + and 8 to 20 digits", 2)
    end
    if recipient_type ~= "phone" and (string.match(recipient_value, "%s") or #recipient_value > 256) then
      error("a BSUID must be an opaque value without whitespace (maximum 256 characters)", 2)
    end
    if options.to_flow and recipient_type ~= "phone" then
      error("WhatsApp Flow and attendance require a phone recipient", 2)
    end
    payload.recipient = { type = recipient_type, value = recipient_value }
  else
    local destination = options.destination or ""
    local phone_digits = string.gsub(destination, "^%+", "")
    if not string.match(phone_digits, "^%d+$") or #phone_digits < 8 or #phone_digits > 20 then
      error("destination must be a phone number; use recipient for BSUID", 2)
    end
    payload.destination = options.destination
  end

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
  local scheme = string.match(path, "^([%a][%w+.-]*):")
  if scheme and string.lower(scheme) ~= "https" then
    error("Nvoip SDK only permits HTTPS requests", 2)
  end
  local url = scheme and path or self.base_url .. path
  if string.lower(url:sub(1, 8)) ~= "https://" then
    error("Nvoip SDK only permits HTTPS requests", 2)
  end
  if http.PROXY then
    error("HTTPS proxy is not supported", 2)
  end

  local cafile, capath = resolve_ca_locations(self.cafile, self.capath)

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

  local request_options = {
    url = url,
    method = method,
    headers = headers,
    source = body and ltn12.source.string(body) or nil,
    sink = ltn12.sink.table(response_chunks),
    protocol = "tlsv1_2",
    verify = "peer",
    cafile = cafile,
    capath = capath,
  }
  request_options.create = verified_tcp(request_options)

  local ok, status_code = http.request(request_options)

  local raw = table.concat(response_chunks)
  local decoded = cjson.decode(raw)
  local payload = decoded or { raw = raw }

  if not ok then
    error(("Nvoip request failed: %s"):format(tostring(status_code)), 2)
  end
  if tonumber(status_code) and tonumber(status_code) >= 400 then
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
