#!/bin/bash

# Actualizar paquetes
echo "Actualizando paquetes..."
sudo apt-get update -y

# Instalar NGINX
echo "Instalando NGINX y Git..."
sudo apt-get install nginx git -y

# Copiar configuración personalizada
echo "Configurando NGINX..."
sudo cp /vagrant/Configs/default.conf /etc/nginx/sites-available/default

## Aplicación
# Ruta raíz del servidor web
NGINGX_ROOT="/var/www"
# Ruta de la aplicación
APP_PATH="$NGINGX_ROOT/utn-devops-app"

if [ ! -d "$NGINGX_ROOT" ]; then
	sudo mkdir -p $NGINGX_ROOT
fi

# Descargar la app del repositorio
echo "Descargando la aplicación..."
if [ ! -d "$APP_PATH" ]; then
	echo "Clonar el repositorio"
	cd $NGINGX_ROOT
	sudo git clone https://github.com/NicolasFrance01/UTN-BA-Practica1.git
fi

# Probar configuración de NGINX
echo "Verificando configuración de NGINX..."
if sudo nginx -t; then
    echo "Configuración OK, reiniciando NGINX..."
    sudo systemctl restart nginx
    echo "NGINX reiniciado correctamente."
else
    echo "❌ Error en la configuración de NGINX. No se reinicia el servicio."
    exit 1
fi
