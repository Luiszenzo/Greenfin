# Verifica que estés copiando todos los archivos
FROM node:18-alpine

WORKDIR /app

# Copiar TODOS los archivos (ajusta según necesites)
COPY . .

RUN npm install --production

EXPOSE 3000

CMD ["node", "index.js"]
