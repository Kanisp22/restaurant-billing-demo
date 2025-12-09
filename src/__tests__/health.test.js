const http = require('http');

// Minimal integration test to check the server boots and responds
function request(path = '/healthz') {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        host: '127.0.0.1',
        port: process.env.PORT || 3000,
        path,
        method: 'GET',
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => resolve({ status: res.statusCode, data }));
      }
    );
    req.on('error', reject);
    req.end();
  });
}

async function run() {
  const server = require('../index'); // starts server
  try {
    const res = await request('/healthz');
    if (res.status !== 200) {
      console.error('Health check failed', res);
      process.exit(1);
    }
    console.log('Health check passed');
    process.exit(0);
  } catch (err) {
    console.error('Test error', err);
    process.exit(1);
  } finally {
    // Let process exit naturally; server stays up only for test run
    server?.close?.();
  }
}

if (require.main === module) {
  run();
}

