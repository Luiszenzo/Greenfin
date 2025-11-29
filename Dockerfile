FROM node:18-alpine

WORKDIR /app

# Copiar package.json primero (para mejor cache de Docker)
COPY package*.json ./

# Instalar dependencias
RUN npm install --production

# Copiar TODOS los archivos del proyecto
COPY . .

# Exponer puerto
EXPOSE 3000

# Variable de entorno
ENV BG_COLOR=blue

# Comando para ejecutar
CMD ["node", "index.js"]
