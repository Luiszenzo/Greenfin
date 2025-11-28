#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${1:-ghcr.io/owner/repo:latest}"
# Normalize image reference to lowercase to satisfy GHCR requirements
IMAGE_TAG="$(echo "$IMAGE_TAG" | tr '[:upper:]' '[:lower:]')"

# Paths Nginx
UPSTREAM_DIR="/etc/nginx/bluegreen"
ACTIVE_LINK="${UPSTREAM_DIR}/bluegreen_upstream_active.conf"
BLUE_CONF="${UPSTREAM_DIR}/bluegreen_upstream_blue.conf"
GREEN_CONF="${UPSTREAM_DIR}/bluegreen_upstream_green.conf"

# Preflight: ensure upstream files exist (self-heal)
if ! sudo -n true 2>/dev/null; then
  echo "ERROR: sudo NOPASSWD no configurado para el usuario $(whoami). Configure sudoers o ejecute con un usuario con permisos."
  exit 1
fi
sudo -n mkdir -p "$UPSTREAM_DIR"
if [ ! -f "$BLUE_CONF" ]; then
  echo "set \$app_upstream http://127.0.0.1:3000;" | sudo -n tee "$BLUE_CONF" >/dev/null
fi
if [ ! -f "$GREEN_CONF" ]; then
  echo "set \$app_upstream http://127.0.0.1:4000;" | sudo -n tee "$GREEN_CONF" >/dev/null
fi
if [ ! -L "$ACTIVE_LINK" ]; then
  sudo -n ln -sfn "$BLUE_CONF" "$ACTIVE_LINK"
fi

# Detección del color activo
ACTIVE_COLOR="none"
if [ -L "$ACTIVE_LINK" ]; then
  TARGET="$(readlink -f "$ACTIVE_LINK" || true)"
  if [[ "$TARGET" == "$BLUE_CONF" ]]; then
    ACTIVE_COLOR="blue"
  elif [[ "$TARGET" == "$GREEN_CONF" ]]; then
    ACTIVE_COLOR="green"
  fi
fi

# Decidir color de despliegue (el inactivo)
if [ "$ACTIVE_COLOR" == "blue" ]; then
  DEPLOY_COLOR="green"
  FRONT_PORT=4000
  CONTAINER_NAME="bluegreen-green"
elif [ "$ACTIVE_COLOR" == "green" ]; then
  DEPLOY_COLOR="blue"
  FRONT_PORT=3000
  CONTAINER_NAME="bluegreen-blue"
else
  DEPLOY_COLOR="blue"
  FRONT_PORT=3000
  CONTAINER_NAME="bluegreen-blue"
fi

echo "Activo: $ACTIVE_COLOR, desplegando: $DEPLOY_COLOR, contenedor: $CONTAINER_NAME"

# Login a GHCR (requiere $REGISTRY_USER y $REGISTRY_TOKEN en entorno)
echo "$REGISTRY_TOKEN" | docker login ghcr.io -u "$REGISTRY_USER" --password-stdin

# Pull de la imagen
docker pull "$IMAGE_TAG"

# Parar/eliminar previo del color de despliegue si existe
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

# Run container: bind host port to container's 3000
docker run -d --name "$CONTAINER_NAME" --restart=always \
  -e COLOR="$DEPLOY_COLOR" \
  -p 127.0.0.1:${FRONT_PORT}:3000 \
  "$IMAGE_TAG"

# Health-check frontend
for i in {1..30}; do
  if curl -fs "http://127.0.0.1:${FRONT_PORT}/status" >/dev/null; then
    echo "Health-check OK en puerto ${FRONT_PORT}"
    break
  fi
  echo "Esperando servicio en puerto ${FRONT_PORT} (intento ${i})..."
  sleep 2
done

# Alternar upstream activo (requires sudo in /etc/nginx)
if [ "$DEPLOY_COLOR" == "blue" ]; then
  sudo -n ln -sfn "$BLUE_CONF" "$ACTIVE_LINK"
else
  sudo -n ln -sfn "$GREEN_CONF" "$ACTIVE_LINK"
fi

# Recargar Nginx
sudo -n nginx -t
sudo -n systemctl restart nginx

echo "Blue-Green alternado a ${DEPLOY_COLOR}. Nginx recargado."
# Opcional: parar contenedor del color anterior (rollback más difícil si se detiene)
# docker stop "nutritrack-${ACTIVE_COLOR}" || true