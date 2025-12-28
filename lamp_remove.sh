#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "⚠️ Esto eliminará Apache, MySQL, PHP y phpMyAdmin"
read -p "¿Seguro que quieres continuar? (s/n): " CONFIRM
if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo "❌ Desinstalación cancelada"
    exit 0
fi

# Ignorar warnings de locale temporalmente
export LC_ALL=C

# --------------------------------------
# Detener servicios
# --------------------------------------
sudo systemctl stop apache2 || true
sudo systemctl stop mysql || true
sudo systemctl stop php*-fpm || true

# --------------------------------------
# Desinstalar Apache
# --------------------------------------
sudo apt purge -y apache2* libapache2* || true
sudo rm -rf /etc/apache2 /var/www/html
sudo apt autoremove -y

# --------------------------------------
# Desinstalar MySQL
# --------------------------------------
sudo apt purge -y dbconfig-mysql default-mysql-client mysql-* || true
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql* || true
sudo apt --fix-broken install -y
sudo apt autoremove -y

# --------------------------------------
# Desinstalar PHP
# --------------------------------------
PHP_PACKAGES="php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip libapache2-mod-php* php*-fpm*"

for pkg in $PHP_PACKAGES; do
    sudo apt purge -y $pkg || true
done
sudo apt autoremove -y

# --------------------------------------
# Desinstalar phpMyAdmin
# --------------------------------------
sudo apt purge -y phpmyadmin || true
sudo rm -rf /usr/share/phpmyadmin /var/www/html/phpmyadmin
sudo apt autoremove -y

# --------------------------------------
# Limpieza final
# --------------------------------------
sudo apt autoremove -y
sudo apt autoclean -y

echo "✅ Desinstalación completa. Tu sistema está limpio."
