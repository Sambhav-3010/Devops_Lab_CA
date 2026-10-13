const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { app } = require('./server');

function request(server, path, method = 'GET') {
  return new Promise((resolve, reject) => {
    const address = server.address();
    const req = http.request({ hostname: '127.0.0.1', port: address.port, path, method }, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
    req.end();
  });
}

test('health endpoint reports a healthy Node.js service', async () => {
  const server = app.listen(0);
  try {
    const response = await request(server, '/health');
    assert.equal(response.status, 200);
    assert.equal(JSON.parse(response.body).status, 'healthy');
  } finally {
    server.close();
  }
});

test('fail endpoint returns deterministic HTTP 503', async () => {
  const server = app.listen(0);
  try {
    const response = await request(server, '/fail');
    assert.equal(response.status, 503);
  } finally {
    server.close();
  }
});

test('metrics endpoint exposes application request metrics', async () => {
  const server = app.listen(0);
  try {
    await request(server, '/health');
    const response = await request(server, '/metrics');
    assert.equal(response.status, 200);
    assert.match(response.body, /demo_http_requests_total/);
    assert.match(response.body, /demo_http_request_duration_seconds_bucket/);
  } finally {
    server.close();
  }
});
