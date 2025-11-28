FROM node:20-alpine

WORKDIR /app

# Copiamos package.json de raíz y del cliente para instalar deps en caché
COPY package.json package-lock.json ./

# Instalación de dependencias
RUN npm ci

# Copiamos el resto del código
COPY . .

EXPOSE 3000

# Arrancamos ambos servicios en paralelo
CMD ["npm", "start"]