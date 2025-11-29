FROM node:18-alpine

WORKDIR /app

# Copiar archivos del proyecto
COPY package*.json ./
COPY *.js ./
COPY *.html ./

RUN npm install --production

EXPOSE 3000

CMD ["node", "index.js"]
