# nvoip-lua

Cliente Lua simples para a API v2 da Nvoip.

## Requisitos

Pacotes recomendados via LuaRocks:

- `luasec`
- `lua-cjson`

## Fluxos cobertos

- gerar `access_token`
- consultar saldo
- enviar SMS

## Configuração

```bash
export NVOIP_NUMBERSIP="seu_numbersip"
export NVOIP_USER_TOKEN="seu_user_token"
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

## Onde este repositório ajuda mais

Lua é especialmente útil em cenários de automação e telefonia embarcada, como integrações com serviços e middlewares que já usam scripts leves para orquestração.

## Documentação oficial

- https://nvoip.docs.apiary.io/
- https://www.nvoip.com.br/api
