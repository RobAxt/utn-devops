#!/bin/bash
set -e

echo "=== Verificando Ubuntu 22.04 (jammy) ==="
if [ ! -f /etc/os-release ]; then
    echo "No se encontró /etc/os-release."
    exit 1
fi

. /etc/os-release

if [[ "$ID" != "ubuntu" || "$VERSION_CODENAME" != "jammy" ]]; then
    echo "Detectado: $PRETTY_NAME"
    exit 1
fi

echo "Sistema detectado: $PRETTY_NAME"
sleep 1

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

echo "=== Transfiriendo configuración y manifiestos desde el Host (/Puppet) ==="

SRC_DIR="/Puppet"

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

# Ajustar permisos después de copiar
sudo chown -R puppet:puppet /etc/puppetlabs


# Habilitar y arrancar puppetserver
sudo systemctl enable puppetserver
sudo systemctl restart puppetserver

# Habilitar el agente de Puppet
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

echo
echo "==============================================="
echo " Puppet agent y master instalados."
echo " Usuario y grupo 'puppet' gestionados."
echo " Configuración y manifiestos copiados (si existen en /Puppet)."
echo " Agente de Puppet habilitado y en ejecución."
echo "==============================================="
echo
