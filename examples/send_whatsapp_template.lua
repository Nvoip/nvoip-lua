local nvoip = require("nvoip")
local cjson = require("cjson.safe")

local client = nvoip.new({
  base_url = os.getenv("NVOIP_BASE_URL") or "https://api.nvoip.com.br/v2",
  oauth_basic_auth = os.getenv("NVOIP_OAUTH_BASIC_AUTH"),
  oauth_client_id = os.getenv("NVOIP_OAUTH_CLIENT_ID"),
  oauth_client_secret = os.getenv("NVOIP_OAUTH_CLIENT_SECRET"),
})

local oauth = client:create_access_token(
  assert(os.getenv("NVOIP_NUMBERSIP"), "NVOIP_NUMBERSIP is required"),
  assert(os.getenv("NVOIP_USER_TOKEN"), "NVOIP_USER_TOKEN is required")
)

local response = client:send_whatsapp_template({
  access_token = oauth.access_token,
  id_template = assert(os.getenv("NVOIP_WA_TEMPLATE_ID"), "NVOIP_WA_TEMPLATE_ID is required"),
  destination = assert(os.getenv("NVOIP_WA_DESTINATION"), "NVOIP_WA_DESTINATION is required"),
  instance = assert(os.getenv("NVOIP_WA_INSTANCE"), "NVOIP_WA_INSTANCE is required"),
  language = os.getenv("NVOIP_WA_LANGUAGE") or "pt_BR",
  to_flow = (os.getenv("NVOIP_WA_TO_FLOW") or "false") == "true",
})

print(cjson.encode(response))
