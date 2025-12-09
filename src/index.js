const express = require('express');

const app = express();
const port = process.env.PORT || 3000;
const build = process.env.BUILD_ID || 'local';

app.get('/', (_req, res) => {
  res.json({
    message: 'Hello from the demo app!',
    build,
    status: 'healthy',
  });
});

app.get('/healthz', (_req, res) => {
  res.status(200).send('ok');
});

const server = app.listen(port, () => {
  console.log(`Server running on port ${port} (build ${build})`);
});

module.exports = server;

