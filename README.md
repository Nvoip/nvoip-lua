# nvoip-lua

SDK e exemplos oficiais da [Nvoip](https://www.nvoip.com.br/) para integrar a API v2 com OAuth, chamadas, OTP, WhatsApp, SMS e saldo em Lua.

## Requisitos

Pacotes recomendados via LuaRocks:

- `luasec`
- `lua-cjson`

## Fluxos cobertos

- gerar `access_token`
- renovar token
- consultar saldo
- enviar SMS
- realizar chamada
- enviar OTP
- validar OTP
- listar templates de WhatsApp
- enviar template de WhatsApp

## Configuração

```bash
export NVOIP_NUMBERSIP="seu_numbersip"
export NVOIP_USER_TOKEN="seu_user_token"
export NVOIP_OAUTH_CLIENT_ID="seu_client_id"
export NVOIP_OAUTH_CLIENT_SECRET="seu_client_secret"
export NVOIP_TARGET_NUMBER="11999999999"
export NVOIP_SMS_MESSAGE="Mensagem de teste Nvoip"
```

## Exemplos

Enviar SMS:

```bash
lua examples/send_sms.lua
```

Consultar saldo:

```bash
lua examples/get_balance.lua
```

Gerar `access_token`:

```bash
lua examples/create_access_token.lua
```

Criar chamada:

```bash
lua examples/create_call.lua
```

Enviar OTP:

```bash
lua examples/send_otp.lua
```

Validar OTP:

```bash
lua examples/check_otp.lua
```

Listar templates de WhatsApp:

```bash
lua examples/list_whatsapp_templates.lua
```

Enviar template de WhatsApp:

```bash
lua examples/send_whatsapp_template.lua
```

## Onde este repositório ajuda mais

Lua é especialmente útil em cenários de automação e telefonia embarcada, como integrações com serviços e middlewares que já usam scripts leves para orquestração.

Para o fluxo de popup de telefone + codigo no navegador, use em conjunto o repositório `nvoip-web-sdk`.

## Documentação oficial

- https://nvoip.docs.apiary.io/
- https://www.nvoip.com.br/api
