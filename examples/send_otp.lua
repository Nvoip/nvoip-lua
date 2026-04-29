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

local response = client:send_otp({
  access_token = oauth.access_token,
  sms = os.getenv("NVOIP_OTP_SMS") or os.getenv("NVOIP_TARGET_NUMBER"),
  voice = os.getenv("NVOIP_OTP_VOICE"),
  email = os.getenv("NVOIP_OTP_EMAIL"),
})

print(cjson.encode(response))
