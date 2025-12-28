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
# Funciones de instalación y desinstalación
# --------------------------------------
install_lamp() {
    echo "🔄 Actualizando sistema..."
    sudo apt update -y && sudo apt upgrade -y

    # Apache
    if package_installed apache2; then
        echo "✅ Apache ya instalado, saltando..."
    else
        echo "🌐 Instalando Apache..."
        sudo apt install -y apache2
    fi
    sudo systemctl enable apache2
    sudo systemctl restart apache2

    # MySQL
    if package_installed mysql-server; then
        echo "✅ MySQL ya instalado, saltando..."
    else
        echo "🛢️ Instalando MySQL..."
        sudo apt install -y mysql-server
    fi
    sudo systemctl enable mysql
    sudo systemctl restart mysql

    # PHP
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

    # phpMyAdmin
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

    if [ ! -L /var/www/html/phpmyadmin ]; then
        sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    fi

    echo "🔐 Configurando contraseña root de MySQL..."
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"

    sudo systemctl restart apache2
    sudo systemctl restart mysql

    # Detectar IP local
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    echo "✅ Stack LAMP listo"
    echo "➡ Accede a phpMyAdmin en: http://${LOCAL_IP}/phpmyadmin"
}

uninstall_lamp() {
    echo "⚠️ Esto eliminará Apache, MySQL, PHP y phpMyAdmin"
    read -p "¿Seguro que quieres continuar? (s/n): " CONFIRM
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
        echo "❌ Desinstalación cancelada"
        exit 0
    fi

    export LC_ALL=C
    sudo systemctl stop apache2 || true
    sudo systemctl stop mysql || true
    sudo systemctl stop php*-fpm || true

    # Apache
    sudo apt purge -y apache2* libapache2* || true
    sudo rm -rf /etc/apache2 /var/www/html
    sudo apt autoremove -y

    # MySQL
    sudo apt purge -y dbconfig-mysql default-mysql-client mysql-* || true
    sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql* || true
    sudo apt --fix-broken install -y
    sudo apt autoremove -y

    # PHP
    PHP_PACKAGES="php php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip libapache2-mod-php* php*-fpm*"
    for pkg in $PHP_PACKAGES; do
        sudo apt purge -y $pkg || true
    done
    sudo apt autoremove -y

    # phpMyAdmin
    sudo apt purge -y phpmyadmin || true
    sudo rm -rf /usr/share/phpmyadmin /var/www/html/phpmyadmin
    sudo apt autoremove -y
    sudo apt autoclean -y

    echo "✅ Desinstalación completa. Tu sistema está limpio."
}

# --------------------------------------
# Menú interactivo
# --------------------------------------
while true; do
    echo "========================================"
    echo "   Script LAMP VPS - Menú Interactivo"
    echo "========================================"
    echo "1) Instalar LAMP"
    echo "2) Desinstalar LAMP"
    echo "3) Salir"
    read -p "Elige una opción [1-3]: " OPTION

    case $OPTION in
        1) install_lamp ;;
        2) uninstall_lamp ;;
        3) echo "Saliendo..."; exit 0 ;;
        *) echo "❌ Opción inválida";;
    esac
done
