#!/bin/bash
set -e

echo "=== Instalando Puppet agent y Puppet master ==="
sudo apt update -y
sudo apt install -y wget lsb-release

PUPPET_DEB="puppet8-release-jammy.deb"
PUPPET_DEB_URL="https://apt.puppet.com/${PUPPET_DEB}"

if [ ! -f "/tmp/${PUPPET_DEB}" ]; then
    wget -q "${PUPPET_DEB_URL}" -O "/tmp/${PUPPET_DEB}"
fi

sudo dpkg -i "/tmp/${PUPPET_DEB}" || true
sudo apt update -y

sudo apt install -y puppetserver puppet-agent

# Asegurar Java (por si la imagen es muy minimal)
if ! java -version >/dev/null 2>&1; then
    sudo apt install -y openjdk-17-jre-headless
fi

echo "=== Gestionando usuario y grupo 'puppet' ==="

if ! getent group puppet >/dev/null 2>&1; then
    sudo groupadd --system puppet
fi

if ! getent passwd puppet >/dev/null 2>&1; then
    sudo useradd \
        --system \
        --gid puppet \
        --home-dir /opt/puppetlabs/server/data/puppetserver \
        --shell /usr/sbin/nologin \
        puppet
fi

PUPPET_CONF_DIR="/etc/puppetlabs/puppet"
PUPPET_ENV_DIR="/etc/puppetlabs/code/environments/production"

sudo mkdir -p "$PUPPET_CONF_DIR"
sudo mkdir -p "$PUPPET_ENV_DIR/manifests"
sudo mkdir -p "$PUPPET_ENV_DIR/modules"

sudo chown -R puppet:puppet /etc/puppetlabs

echo "=== Transfiriendo configuración y manifiestos desde el Host (/Vagrant/Puppet) ==="

SRC_DIR="/Vagrant/Puppet"

if [ -d "$SRC_DIR" ]; then
    echo "Usando directorio de Puppet en host: $SRC_DIR"

    # puppet.conf opcional desde el host
    if [ -f "$SRC_DIR/puppet.conf" ]; then
        echo "Copiando puppet.conf desde host..."
        sudo cp "$SRC_DIR/puppet.conf" "$PUPPET_CONF_DIR/puppet.conf"
    fi

    # Copiar manifests/ y modules/ si existen
    if [ -d "$SRC_DIR/manifests" ]; then
        echo "Copiando manifests/..."
        sudo cp -r "$SRC_DIR/manifests/"* "$PUPPET_ENV_DIR/manifests/" || true
    fi

    if [ -d "$SRC_DIR/modules" ]; then
        echo "Copiando modules/..."
        sudo cp -r "$SRC_DIR/modules/"* "$PUPPET_ENV_DIR/modules/" || true
    fi

else
    echo "[ADVERTENCIA] No existe el directorio $SRC_DIR."
fi

echo "=== Configurando /etc/hosts para Puppet ==="
HOST_FILE="/etc/hosts"
NEW_LOCALHOST="127.0.0.1  ubuntu-devops"

echo "Agregando entrada a /etc/hosts..."
echo "$NEW_LOCALHOST" | sudo tee -a "$HOST_FILE" > /dev/null

# Ajustar permisos después de copiar
sudo chown -R puppet:puppet /etc/puppetlabs

# Limpiar certificados SSL previos
sudo rm -rf /var/lib/puppet/ssl

# Habilitar y arrancar puppetserver
sudo systemctl enable puppetserver
sudo systemctl restart puppetserver

echo "=== Configurando Puppet agent ==="
# Habilitar el agente de Puppet
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

# Ejecutar el agente de Puppet una vez
sudo /opt/puppetlabs/bin/puppet agent -t

