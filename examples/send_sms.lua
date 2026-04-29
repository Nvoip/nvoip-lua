local nvoip = require("nvoip")

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

local response = client:send_sms({
  number_phone = os.getenv("NVOIP_TARGET_NUMBER") or "11999999999",
  message = os.getenv("NVOIP_SMS_MESSAGE") or "Mensagem de teste Nvoip",
  access_token = oauth.access_token
})

print(require("cjson.safe").encode(response))
