#!/bin/bash

# Crear usuario sudo USER_NAME y su configuracion.
	# useradd USER_NAME
	# echo "Passw0rd" | passwd --stdin USER_NAME
	# usermod -aG wheel USER_NAME
	# mkhomedir_helper USER_NAME
	# mkdir /home/USER_NAME/.ssh
	# touch /home/USER_NAME/.ssh/authorized_keys
	# echo -e "PUBLIC_KEY.PUB" > /home/USER_NAME/.ssh/authorized_keys
	# chown USER_NAME:USER_NAME /home/USER_NAME/.ssh
	# chown USER_NAME:USER_NAME/home/USER_NAME/.ssh/*

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
		mysqladmin -u root password 'Passw0rd'
		## Eliminar usuarios anónimos
		mysql -u root -p='Passw0rd' -e "DELETE FROM mysql.user WHERE User='';"
		## Eliminar acceso remoto para root
		mysql -u root -p='Passw0rd' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
		## Eliminar base de datos de prueba y cualquier acceso a ella
		mysql -u root -p='Passw0rd' -e "DROP DATABASE IF EXISTS test;"
		mysql -u root -p='Passw0rd' -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
		## Aplicar cambios
		mysql -u root -p='Passw0rd' -e "FLUSH PRIVILEGES;"
	mysql -u root -p='Passw0rd' -e "CREATE DATABASE wordpress;"
	mysql -u root -p='Passw0rd' -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'Passw0rd';"
	mysql -u root -p='Passw0rd' -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';"
	mysql -u root -p='Passw0rd' -e "FLUSH PRIVILEGES;"

# configurar UFW
	ufw allow http
	ufw allow https
	systemctl restart apache2

# Descargar e instalar Wordpress 6.2
	wget -P /var/www/html/ https://es.wordpress.org/wordpress-6.2-es_ES.tar.gz
	tar -xzf /var/www/html/wordpress-6.2-es_ES.tar.gz -C /var/www/html/
	mv /var/www/html/wordpress/* /var/www/html/
	rm -rf /var/www/html/wordpress/ /var/www/html/index.htm
l	cp /var/www/html/wp-config-sample.php /var/www/html/wp-config-sample.old
	mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', 'wordpress' );/" /var/www/html/wp-config.php
	sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', 'wordpress' );/" /var/www/html/wp-config.php
	sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', 'Passw0rd' );/" /var/www/html/wp-config.php

# configuracion permisos para apache
	chown -R www-data /var/www/html/
#	chcon -t apache2_sys_rw_content_t /var/www/html/ -R
#	restorecon -Rv /var/www/html/
	chmod -Rf 755 /var/www/html/
#	semanage fcontext -a -t apache2_sys_rw_content_t "/var/www/html(/.*)?"
	systemctl restart apache2
