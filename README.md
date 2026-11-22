# nvoip-lua

[![CI](https://github.com/Nvoip/nvoip-lua/actions/workflows/ci.yml/badge.svg)](https://github.com/Nvoip/nvoip-lua/actions/workflows/ci.yml) [![LuaRocks](https://img.shields.io/luarocks/v/nvoip/nvoip?style=flat-square)](https://luarocks.org/modules/nvoip/nvoip) [![LuaRocks downloads](https://img.shields.io/luarocks/dt/nvoip/nvoip?style=flat-square)](https://luarocks.org/modules/nvoip/nvoip) [![Nvoip](https://img.shields.io/badge/Nvoip-site-00A3E0?style=flat-square)](https://www.nvoip.com.br/) [![API v3](https://img.shields.io/badge/API-v3-1F6FEB?style=flat-square)](https://www.nvoip.com.br/api/) [![Docs](https://img.shields.io/badge/docs-Apiary-6A737D?style=flat-square)](https://nvoip.docs.apiary.io/) [![Postman](https://img.shields.io/badge/Postman-workspace-FF6C37?style=flat-square)](https://nvoip-api.postman.co/workspace/e671d01f-168a-4c38-8d0e-c217229dd61a/team-quickstart) [![Stack](https://img.shields.io/badge/stack-Lua-000080?style=flat-square)](https://github.com/Nvoip/nvoip-api-examples) [![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue?style=flat-square)](LICENSE)

SDK e exemplos oficiais da [Nvoip](https://www.nvoip.com.br/) para integrar a API v3 com OAuth, chamadas, OTP, WhatsApp, SMS e saldo em Lua.

## Requisitos

Pacotes recomendados via LuaRocks:

- `luasec >= 1.3.2`
- `lua-cjson`

## Instalacao

```bash
luarocks install nvoip
```

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
export NVOIP_OAUTH_CLIENT_ID="seu_client_id"
export NVOIP_OAUTH_CLIENT_SECRET="seu_client_secret"
export NVOIP_TARGET_NUMBER="11999999999"
export NVOIP_SMS_MESSAGE="Mensagem de teste Nvoip"
```

O SDK valida a cadeia e o `subjectAltName` do certificado TLS antes de enviar a
requisição. Em Linux, macOS e BSD ele procura os bundles de CA usuais do
sistema. Em ambientes com store próprio (incluindo Windows), configure
`SSL_CERT_FILE`/`SSL_CERT_DIR` ou informe `cafile`/`capath` ao criar o cliente:

```lua
local client = require("nvoip").new({
  oauth_client_id = os.getenv("NVOIP_OAUTH_CLIENT_ID"),
  oauth_client_secret = os.getenv("NVOIP_OAUTH_CLIENT_SECRET"),
  cafile = os.getenv("NVOIP_CA_FILE"),
})
```

O transporte recusa HTTP, certificado de CA desconhecida, nome DNS/IP divergente
e certificado sem `subjectAltName`; não há fallback inseguro para o CN.

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

### Destinatário WhatsApp

O exemplo mantém `NVOIP_WA_DESTINATION` para telefone. Para o contrato tipado,
use `NVOIP_WA_RECIPIENT_TYPE=phone|bsuid|parent_bsuid` e
`NVOIP_WA_RECIPIENT_VALUE`, sem `destination`. BSUID é opaco; não use
`@username` nem o coloque em campo de telefone. Exemplos mascarados:
`US.MASKED_BSUID_001` e `PARENT.MASKED_BSUID_001`.

## Onde este repositório ajuda mais

Lua é especialmente útil em cenários de automação e telefonia embarcada, como integrações com serviços e middlewares que já usam scripts leves para orquestração.

Para o fluxo de popup de telefone + codigo no navegador, use em conjunto o repositório `nvoip-web-sdk`.

## Links oficiais

- [Site da Nvoip](https://www.nvoip.com.br/)
- [Documentação da API](https://nvoip.docs.apiary.io/)
- [Página da API](https://www.nvoip.com.br/api/)
- [Workspace Postman](https://nvoip-api.postman.co/workspace/e671d01f-168a-4c38-8d0e-c217229dd61a/team-quickstart)
- [Hub de exemplos](https://github.com/Nvoip/nvoip-api-examples)
