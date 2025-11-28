const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const color = process.env.COLOR || 'unknown';

const publicPath = __dirname;
app.use(express.static(publicPath));

app.get('/status', (req, res) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.json({ color, hostname: os.hostname(), envColor: process.env.COLOR || null });
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0');