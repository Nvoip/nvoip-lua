local nvoip = require("nvoip")
local cjson = require("cjson.safe")

local client = nvoip.new({
  base_url = os.getenv("NVOIP_BASE_URL") or "https://api.nvoip.com.br/v2",
  oauth_client_id = os.getenv("NVOIP_OAUTH_CLIENT_ID"),
  oauth_client_secret = os.getenv("NVOIP_OAUTH_CLIENT_SECRET"),
})

local oauth = client:create_access_token(
  assert(os.getenv("NVOIP_NUMBERSIP"), "NVOIP_NUMBERSIP is required"),
  assert(os.getenv("NVOIP_USER_TOKEN"), "NVOIP_USER_TOKEN is required")
)

local recipient_type = os.getenv("NVOIP_WA_RECIPIENT_TYPE")
local options = {
  access_token = oauth.access_token,
  id_template = assert(os.getenv("NVOIP_WA_TEMPLATE_ID"), "NVOIP_WA_TEMPLATE_ID is required"),
  instance = assert(os.getenv("NVOIP_WA_INSTANCE"), "NVOIP_WA_INSTANCE is required"),
  language = os.getenv("NVOIP_WA_LANGUAGE") or "pt_BR",
  to_flow = (os.getenv("NVOIP_WA_TO_FLOW") or "false") == "true",
}
if recipient_type then
  options.recipient = {
    type = recipient_type,
    value = assert(os.getenv("NVOIP_WA_RECIPIENT_VALUE"), "NVOIP_WA_RECIPIENT_VALUE is required"),
  }
else
  options.destination = assert(os.getenv("NVOIP_WA_DESTINATION"), "NVOIP_WA_DESTINATION is required")
end

local response = client:send_whatsapp_template(options)

print(cjson.encode(response))
