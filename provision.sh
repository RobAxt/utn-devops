#!/bin/bash

# Actualizar paquetes
echo "Actualizando paquetes..."
sudo apt update -y

# Instalar Docker
sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker $USER

sudo systemctl start docker
sudo systemctl enable docker

# Verificar instalación de Docker
if ! docker --version >/dev/null 2>&1; then
    echo "El binario de Docker existe, pero no responde correctamente."
    exit 1
fi
echo "Docker instalado correctamente."

APP_ROOT="/vagrant/Docker"
# Ruta de la aplicación
APP_PATH="$APP_ROOT/utn-devops-app"

# Descargar la app del repositorio
echo "Descargando la aplicación..."
if [ ! -d "$APP_PATH" ]; then
	echo "Clonar el repositorio"
	cd $APP_ROOT
	sudo git clone https://github.com/RobAxt/utn-devops-app.git
    cd $APP_PATH
    sudo git checkout utn-ba-practica2
fi

# Construir y ejecutar la aplicación con Docker Compose
echo "Construyendo y ejecutando la aplicación con Docker Compose..."
cd $APP_PATH
sudo docker compose up -d --build   
