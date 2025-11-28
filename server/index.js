const express = require('express');
const path = require('path');

const app = express();
const color = process.env.COLOR || 'unknown';

const publicPath = __dirname;
app.use(express.static(publicPath));

app.get('/status', (req, res) => {
  res.json({ color });
});

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0');