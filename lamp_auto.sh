#!/bin/bash
set -e

# --------------------------------------
# Variables (ajustables)
# --------------------------------------
PMA_DB_PASS="pma_pass_123"
MYSQL_ROOT_PASS="root_pass_123"

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------
# Funciones de verificación
# --------------------------------------
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# --------------------------------------
# Actualización del sistema
# --------------------------------------
echo "🔄 Actualizando sistema..."
sudo apt update -y && sudo apt upgrade -y

# --------------------------------------
# Apache
# --------------------------------------
if package_installed apache2; then
    echo "✅ Apache ya instalado, saltando..."
else
    echo "🌐 Instalando Apache..."
    sudo apt install -y apache2
fi
sudo systemctl enable apache2
sudo systemctl restart apache2

# --------------------------------------
# MySQL
# --------------------------------------
if package_installed mysql-server; then
    echo "✅ MySQL ya instalado, saltando..."
else
    echo "🛢️ Instalando MySQL..."
    sudo apt install -y mysql-server
fi
sudo systemctl enable mysql
sudo systemctl restart mysql

# --------------------------------------
# PHP y extensiones
# --------------------------------------
PHP_PACKAGES="php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip libapache2-mod-php"

for pkg in $PHP_PACKAGES; do
    if package_installed $pkg; then
        echo "✅ $pkg ya instalado"
    else
        echo "🐘 Instalando $pkg..."
        sudo apt install -y $pkg
    fi
done

sudo systemctl restart apache2

# --------------------------------------
# phpMyAdmin
# --------------------------------------
if [ -d /usr/share/phpmyadmin ]; then
    echo "✅ phpMyAdmin ya instalado, saltando..."
else
    echo "🧰 Instalando phpMyAdmin..."
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password ${PMA_DB_PASS}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${MYSQL_ROOT_PASS}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${PMA_DB_PASS}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

    sudo apt install -y phpmyadmin
fi

# Enlace en /var/www/html
if [ ! -L /var/www/html/phpmyadmin ]; then
    echo "🔗 Creando enlace phpMyAdmin..."
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
fi

# --------------------------------------
# Configurar MySQL root password
# --------------------------------------
echo "🔐 Configurando contraseña root de MySQL..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"

sudo systemctl restart apache2
sudo systemctl restart mysql

# --------------------------------------
# Finalización
# --------------------------------------
echo "✅ Stack LAMP listo"
echo "➡ Accede a phpMyAdmin en: http://IP_DEL_SERVIDOR/phpmyadmin"
