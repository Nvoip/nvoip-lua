local nvoip = require("nvoip")
local cjson = require("cjson.safe")

local client = nvoip.new({
  base_url = os.getenv("NVOIP_BASE_URL") or "https://api.nvoip.com.br/v3",
})

local oauth = client:create_access_token()
local response = client:check_otp(
  oauth.access_token,
  assert(os.getenv("NVOIP_OTP_CODE"), "NVOIP_OTP_CODE is required"),
  assert(os.getenv("NVOIP_OTP_KEY"), "NVOIP_OTP_KEY is required")
)

print(cjson.encode(response))
