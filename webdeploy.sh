#!/bin/bash

# =====================================
# title             : start_script.sh
# description       : Auto deploy LAMP + Wordpress
# author            : Carlos Hernandez Navarro
# date              : 20/04/2023
# version	    : 0.8.98a (on alfa testing)
# =====================================
# 
# Variables
	## Admin user:
 		USER_NAME="username_here"
 		pass_user="password_here"
 		pub_key="PUBLIC_KEY.PUB"
 	## wordpress database:
 		db_wp_name="database_name_here"
 		db_wp_user="username_here"
 		db_wp_pass="password_here"
 	## root database password:
 		db_root_pass="password_here"

# Crear usuario sudo para administracion y su configuracion.
#	useradd $USER_NAME
#	echo "$pass_user" | passwd --stdin $USER_NAME
#	usermod -aG wheel $USER_NAME
#	mkhomedir_helper $USER_NAME
#	mkdir /home/$USER_NAME/.ssh
#	touch /home/$USER_NAME/.ssh/authorized_keys
#	echo -e "$pub_key" > /home/$USER_NAME/.ssh/authorized_keys
#	chown $USER_NAME:$USER_NAME /home/$USER_NAME/.ssh
#	chown $USER_NAME:$USER_NAME/home/$USER_NAME/.ssh/*

# Actualizar paquetes
	add-apt-repository -y ppa:ondrej/php
	apt update -y

# Instalar LAMP con PHP 7.4
	apt install -y php7.4 php7.4-common php7.4-mysql php7.4-curl php7.4-json php7.4-mbstring php7.4-xml php7.4-zip php7.4-gd php7.4-soap php7.4-ssh2 php7.4-tokenizer
	apt install -y apache2 mariadb-server mariadb-client wget curl git rsync php-xmlrpc php-intl gcc perl policycoreutils-python-utils openssl

# Iniciar servicios de LAMP
	systemctl start apache2.service
	systemctl enable apache2.service
	systemctl start mariadb.service 
	systemctl enable mariadb.service

# Configurar base de datos de Wordpress
		# secure configuration
		mysqladmin -u root password '$db_root_pass'
		## Eliminar usuarios anónimos
		mysql -u root -p='$db_root_pass' -e "DELETE FROM mysql.user WHERE User='';"
		## Eliminar acceso remoto para root
		mysql -u root -p='$db_root_pass' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
		## Eliminar base de datos de prueba y cualquier acceso a ella
		mysql -u root -p='$db_root_pass' -e "DROP DATABASE IF EXISTS test;"
		mysql -u root -p='$db_root_pass' -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
		## Aplicar cambios
		mysql -u root -p='$db_root_pass' -e "FLUSH PRIVILEGES;"
	mysql -u root -p='$db_root_pass' -e "CREATE DATABASE $db_wp_name;"
	mysql -u root -p='$db_root_pass' -e "CREATE USER '$db_wp_user'@'localhost' IDENTIFIED BY '$db_wp_pass';"
	mysql -u root -p='$db_root_pass' -e "GRANT ALL PRIVILEGES ON $db_wp_name.* TO '$db_wp_user'@'localhost';"
	mysql -u root -p='$db_root_pass' -e "FLUSH PRIVILEGES;"

# configurar UFW
	ufw allow http
	ufw allow https
	systemctl restart apache2

# Descargar e instalar Wordpress 6.2
	wget -P /var/www/html/ https://es.wordpress.org/wordpress-6.2-es_ES.tar.gz
	tar -xzf /var/www/html/wordpress-6.2-es_ES.tar.gz -C /var/www/html/
	mv /var/www/html/wordpress/* /var/www/html/
	rm -rf /var/www/html/wordpress/ /var/www/html/index.html
	cp /var/www/html/wp-config-sample.php /var/www/html/wp-config-sample.old
	mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$db_wp_name' );/" /var/www/html/wp-config.php
	sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$db_wp_user' );/" /var/www/html/wp-config.php
	sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$db_wp_pass' );/" /var/www/html/wp-config.php

# configuracion permisos para apache
	chown -R www-data /var/www/html/
	chmod -Rf 755 /var/www/html/
	systemctl restart apache2
