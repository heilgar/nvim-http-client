const http = require('http');
const http2 = require('http2');
const fs = require('fs');

const port = 3000;

const content = {
    json: { message: "This is a dummy JSON response" },
    xml: '<response><message>This is a dummy XML response</message></response>',
    html: '<html><body><h1>This is a dummy HTML response</h1></body></html>',
    text: 'This is a dummy text response'
}

const requestHandler = (req, res) => {
    let body = '';

    req.on('data', chunk => {
        body += chunk.toString();
    });

    req.on('end', () => {
        // Log request information
        console.log(`HTTP/${req.httpVersion} ${req.method} ${req.url} ${body}`);

        const contentType = req.headers['content-type'] || '';
        const acceptHeader = req.headers['accept'] || '';

        let responseContentType;
        let responseBody;

        if (body) {
            responseBody = body;
            responseContentType = contentType;
        } else {
            if (acceptHeader.includes('application/json') || contentType.includes('application/json')) {
                responseContentType = 'application/json';
                responseBody = JSON.stringify(content.json);
            } else if (acceptHeader.includes('application/xml') || contentType.includes('application/xml')) {
                responseContentType = 'application/xml';
                responseBody = content.xml;
            } else if (acceptHeader.includes('text/html') || contentType.includes('text/html')) {
                responseContentType = 'text/html';
                responseBody = content.html;
            } else {
                responseContentType = 'text/plain';
                responseBody = content.text;
            }
        }

        const response = {
            httpVersion: req.httpVersion,
            method: req.method,
            url: req.url,
            headers: req.headers,
            body: responseBody
        };

        res.writeHead(200, {
            'Content-Type': responseContentType,
            'X-Request-Info': JSON.stringify(response)
        });
        res.end(responseBody);
    });
};

const httpServer = http.createServer(requestHandler);

httpServer.listen(port, () => {
    console.log(`HTTP/1.1 server running on http://localhost:${port}`);
});

const http2Server = http2.createSecureServer({
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
}, (req, res) => {
    requestHandler(req, res);
});

http2Server.listen(port + 1, () => {
    console.log(`HTTP/2 server running on https://localhost:${port + 1}`);
});

