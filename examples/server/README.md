# Example server

Dummy HTTP/1.1 and HTTP/2 server used to exercise the plugin's requests.

```sh
node server.js
```

- HTTP/1.1 listens on `http://localhost:8090`
- HTTP/2 listens on `https://localhost:8091`

The HTTP/2 listener needs a certificate. It is not committed — generate one first:

```sh
./generate-cert.sh
```

This writes `key.pem` and `cert.pem` for `localhost` into this directory; both are
gitignored. Without them the HTTP/1.1 listener still starts and HTTP/2 is skipped.

The certificate is self-signed, so point the plugin at the `http2` environment in
`examples/.env.json`, which sets `verifyHostCertificate: false`.
