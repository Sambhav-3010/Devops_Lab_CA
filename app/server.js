const express = require('express');
const crypto = require('crypto');
const os = require('os');

const app = express();
const port = Number(process.env.PORT || 8000);
const memoryBlocks = [];
const requestCounts = new Map();
const histograms = new Map();
const buckets = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 30];

function labels(values) {
  return Object.entries(values)
    .map(([key, value]) => `${key}="${String(value).replaceAll('"', '\\"')}"`)
    .join(',');
}

function recordRequest(method, endpoint, status, seconds) {
  const key = JSON.stringify({ method, endpoint, status });
  requestCounts.set(key, (requestCounts.get(key) || 0) + 1);

  if (!histograms.has(endpoint)) {
    histograms.set(endpoint, { count: 0, sum: 0, buckets: buckets.map(() => 0) });
  }
  const histogram = histograms.get(endpoint);
  histogram.count += 1;
  histogram.sum += seconds;
  buckets.forEach((bucket, index) => {
    if (seconds <= bucket) histogram.buckets[index] += 1;
  });
}

function metricsText() {
  const lines = [
    '# HELP demo_http_requests_total Total HTTP requests handled by the demo application',
    '# TYPE demo_http_requests_total counter',
  ];
  for (const [key, value] of requestCounts) {
    lines.push(`demo_http_requests_total{${labels(JSON.parse(key))}} ${value}`);
  }
  lines.push('# HELP demo_http_request_duration_seconds HTTP request duration in seconds');
  lines.push('# TYPE demo_http_request_duration_seconds histogram');
  for (const [endpoint, histogram] of histograms) {
    histogram.buckets.forEach((count, index) => {
      lines.push(`demo_http_request_duration_seconds_bucket{${labels({ endpoint, le: buckets[index] })}} ${count}`);
    });
    lines.push(`demo_http_request_duration_seconds_bucket{${labels({ endpoint, le: '+Inf' })}} ${histogram.count}`);
    lines.push(`demo_http_request_duration_seconds_sum{${labels({ endpoint })}} ${histogram.sum}`);
    lines.push(`demo_http_request_duration_seconds_count{${labels({ endpoint })}} ${histogram.count}`);
  }
  lines.push('# HELP demo_nodejs_process_resident_memory_bytes Resident memory used by the Node.js process');
  lines.push('# TYPE demo_nodejs_process_resident_memory_bytes gauge');
  lines.push(`demo_nodejs_process_resident_memory_bytes{service="demo-app",instance="${os.hostname()}"} ${process.memoryUsage().rss}`);
  lines.push('# HELP demo_nodejs_process_cpu_seconds_total Total user and system CPU time used by the Node.js process');
  lines.push('# TYPE demo_nodejs_process_cpu_seconds_total counter');
  const cpu = process.cpuUsage();
  lines.push(`demo_nodejs_process_cpu_seconds_total{service="demo-app",instance="${os.hostname()}"} ${(cpu.user + cpu.system) / 1000000}`);
  return `${lines.join('\n')}\n`;
}

app.use((req, res, next) => {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    if (req.path === '/metrics') return;
    const endpoint = req.route?.path || req.path || 'unknown';
    const seconds = Number(process.hrtime.bigint() - start) / 1e9;
    recordRequest(req.method, endpoint, res.statusCode, seconds);
  });
  next();
});

app.get('/', (req, res) => {
  res.json({
    project: 'Kubernetes Workload Reliability and Resource Pressure Analysis',
    runtime: 'Node.js + Express',
    status: 'running',
    endpoints: ['/health', '/metrics', '/fail', '/load?mode=cpu&seconds=10', '/load?mode=memory&mb=10', '/load?mode=error', '/reset'],
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', runtime: 'nodejs' });
});

app.get('/metrics', (req, res) => {
  res.type('text/plain; version=0.0.4').send(metricsText());
});

app.get('/fail', (req, res) => {
  res.status(503).json({
    error: 'Intentional demo outage',
    message: 'This endpoint always returns HTTP 503 for alert demonstrations.',
  });
});

app.get('/load', (req, res) => {
  const mode = String(req.query.mode || 'cpu');
  if (mode === 'cpu') {
    const requested = Number(req.query.seconds || 10);
    const seconds = Math.min(Math.max(Number.isFinite(requested) ? requested : 10, 1), 30);
    const end = Date.now() + seconds * 1000;
    let value = 0;
    while (Date.now() < end) value += Math.sqrt(12345.6789);
    return res.json({ mode, duration_seconds: seconds, result: value });
  }
  if (mode === 'memory') {
    const requested = Number(req.query.mb || 10);
    const mb = Math.min(Math.max(Number.isFinite(requested) ? Math.floor(requested) : 10, 1), 15);
    if (memoryBlocks.length >= 6) return res.status(429).json({ error: 'Memory demo limit reached; call /reset first' });
    memoryBlocks.push(Buffer.alloc(mb * 1024 * 1024, crypto.randomBytes(1)));
    return res.json({ mode, allocated_mb: mb, blocks: memoryBlocks.length });
  }
  if (mode === 'error') return res.status(500).json({ error: 'Intentional demo failure' });
  return res.status(400).json({ error: 'Use mode=cpu, memory, or error' });
});

app.post('/reset', (req, res) => {
  memoryBlocks.length = 0;
  res.json({ status: 'reset', memory_blocks: 0 });
});

if (require.main === module) {
  app.listen(port, '0.0.0.0', () => {
    console.log(`Node.js + Express workload demo listening on port ${port}`);
  });
}

module.exports = { app, metricsText };
