#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/nn-7243-tls.XXXXXX")"
lua_bin="${LUA:-lua}"
server_pid=""
cleanup() {
  if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid"
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$tmp_dir/ca.key" -out "$tmp_dir/ca.crt" \
  -subj "/CN=NN-7243 Test CA" -days 1 >/dev/null 2>&1
openssl req -newkey rsa:2048 -nodes \
  -keyout "$tmp_dir/server.key" -out "$tmp_dir/server.csr" \
  -subj "/CN=unused.invalid" >/dev/null 2>&1
printf 'subjectAltName=IP:127.0.0.1\n' > "$tmp_dir/server.ext"
openssl x509 -req -in "$tmp_dir/server.csr" \
  -CA "$tmp_dir/ca.crt" -CAkey "$tmp_dir/ca.key" -CAcreateserial \
  -out "$tmp_dir/server.crt" -days 1 -sha256 \
  -extfile "$tmp_dir/server.ext" >/dev/null 2>&1

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$tmp_dir/unknown-ca.key" -out "$tmp_dir/unknown-ca.crt" \
  -subj "/CN=NN-7243 Unknown CA" -days 1 >/dev/null 2>&1

port="$("$lua_bin" -e 'local socket = require("socket"); local listener = assert(socket.bind("127.0.0.1", 0)); local _, selected = listener:getsockname(); print(selected); listener:close()')"

openssl s_server -quiet -www -accept "127.0.0.1:$port" \
  -cert "$tmp_dir/server.crt" -key "$tmp_dir/server.key" \
  >"$tmp_dir/server.log" 2>&1 &
server_pid=$!

for _ in $(seq 1 50); do
  if openssl s_client -connect "127.0.0.1:$port" -CAfile "$tmp_dir/ca.crt" \
      </dev/null >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
kill -0 "$server_pid"

"$lua_bin" tests/tls_integration.lua success 127.0.0.1 "$port" "$tmp_dir/ca.crt"
"$lua_bin" tests/tls_integration.lua failure localhost "$port" "$tmp_dir/ca.crt" "TLS hostname verification failed"
"$lua_bin" tests/tls_integration.lua failure 127.0.0.1 "$port" "$tmp_dir/unknown-ca.crt" "certificate verify failed"

