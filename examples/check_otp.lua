local nvoip = require("nvoip")
local cjson = require("cjson.safe")

local client = nvoip.new({
  base_url = os.getenv("NVOIP_BASE_URL") or "https://api.nvoip.com.br/v2",
})

local response = client:check_otp(
  assert(os.getenv("NVOIP_OTP_CODE"), "NVOIP_OTP_CODE is required"),
  assert(os.getenv("NVOIP_OTP_KEY"), "NVOIP_OTP_KEY is required")
)

print(cjson.encode(response))
