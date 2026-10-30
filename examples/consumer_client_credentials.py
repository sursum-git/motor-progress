"""Consulta MED com token em memória e renovação automática. Python 3.10+.

Defina SURSUM_CLIENT_ID e SURSUM_CLIENT_SECRET pelo cofre da integração.
Não imprima os valores dessas variáveis nem habilite logs de corpos HTTP.
"""
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request

TOKEN_URL = 'https://iol.imatextil.com.br/query-progress/api/token.php'
QUERY_URL = 'https://iol.imatextil.com.br/query-progress/api/query.php'


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        return None


class ConsumerClient:
    def __init__(self, client_id, client_secret, *, opener=None, clock=None):
        self._client_id = client_id
        self._client_secret = client_secret
        self._open = opener or urllib.request.build_opener(_NoRedirect()).open
        self._clock = clock or time.monotonic
        self._token = ''
        self._renew_at = 0
        self._lock = threading.Lock()

    def _access_token(self):
        with self._lock:
            if not self._token or self._clock() >= self._renew_at:
                started = self._clock()
                body = urllib.parse.urlencode({
                    'grant_type': 'client_credentials',
                    'client_id': self._client_id,
                    'client_secret': self._client_secret,
                }).encode()
                request = urllib.request.Request(TOKEN_URL, data=body, headers={
                    'Content-Type': 'application/x-www-form-urlencoded',
                })
                with self._open(request, timeout=40) as response:
                    result = json.load(response)
                if result.get('token_type') != 'Bearer' or result.get('expires_in') != 900:
                    raise RuntimeError('Resposta de autenticacao invalida.')
                token = result.get('access_token', '')
                if len(token) != 64 or any(c not in '0123456789abcdef' for c in token):
                    raise RuntimeError('Token invalido.')
                self._token = token
                self._renew_at = started + 870  # margem de 30s, usando relógio monotônico
            return self._token

    def query(self, code, filters):
        body = json.dumps({'code': code, 'parameters': {'querystring': filters}}).encode()
        for attempt in range(2):
            token = self._access_token()
            request = urllib.request.Request(QUERY_URL, data=body, headers={
                'Content-Type': 'application/json', 'X-Sursum-Query-Token': token,
            })
            try:
                with self._open(request, timeout=130) as response:
                    return json.load(response)
            except urllib.error.HTTPError as error:
                if error.code != 401 or attempt:
                    raise
                # Uma única nova autenticação. 403 nunca causa repetição/elevação de escopo.
                with self._lock:
                    if self._token == token:
                        self._token = ''
                        self._renew_at = 0


if __name__ == '__main__':
    client = ConsumerClient(os.environ['SURSUM_CLIENT_ID'], os.environ['SURSUM_CLIENT_SECRET'])
    result = client.query('saldo-estoque-por-referencia', {
        'estabelecimento': '502', 'deposito': 'ARM', 'item': '130062', 'referencia': '004',
    })
    print(json.dumps(result, ensure_ascii=False))
