FROM node:18-alpine

WORKDIR /app

# Copiar package.json primero
COPY package*.json ./

# Instalar dependencias
RUN npm install --production

# Copiar archivos del servidor (desde la carpeta server/)
COPY server/ ./

# Exponer puerto
EXPOSE 3000

# Comando para ejecutar
CMD ["node", "index.js"]
