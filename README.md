# nvoip-lua

[![Nvoip](https://img.shields.io/badge/Nvoip-site-00A3E0?style=flat-square)](https://www.nvoip.com.br/) [![API v2](https://img.shields.io/badge/API-v2-1F6FEB?style=flat-square)](https://www.nvoip.com.br/api/) [![Docs](https://img.shields.io/badge/docs-Apiary-6A737D?style=flat-square)](https://nvoip.docs.apiary.io/) [![Postman](https://img.shields.io/badge/Postman-workspace-FF6C37?style=flat-square)](https://nvoip-api.postman.co/workspace/e671d01f-168a-4c38-8d0e-c217229dd61a/team-quickstart) [![Stack](https://img.shields.io/badge/stack-Lua-000080?style=flat-square)](https://github.com/Nvoip/nvoip-api-examples) [![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue?style=flat-square)](LICENSE)

SDK e exemplos oficiais da [Nvoip](https://www.nvoip.com.br/) para integrar a API v2 com OAuth, chamadas, OTP, WhatsApp, SMS e saldo em Lua.

## Requisitos

Pacotes recomendados via LuaRocks:

- `luasec`
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

## Links oficiais

- [Site da Nvoip](https://www.nvoip.com.br/)
- [Documentação da API](https://nvoip.docs.apiary.io/)
- [Página da API](https://www.nvoip.com.br/api/)
- [Workspace Postman](https://nvoip-api.postman.co/workspace/e671d01f-168a-4c38-8d0e-c217229dd61a/team-quickstart)
- [Hub de exemplos](https://github.com/Nvoip/nvoip-api-examples)
