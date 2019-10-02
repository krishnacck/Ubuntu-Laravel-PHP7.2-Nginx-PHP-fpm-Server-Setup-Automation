echo -n "Please Type Your Domain Name=="
read answer
if whiptail --yesno "You are installing $answer. Are you sure want to continue?" 20 60 ;then
	fallocate -l 8G /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
	sysctl vm.swappiness=10
	sudo apt-get update
	apt-get install software-properties-common -y 
	apt-get install python-software-properties -y
	add-apt-repository ppa:ondrej/php -y
	apt-get -y install unzip zip nginx php7.2 php7.2-mysql php7.2-fpm php7.2-mbstring php7.2-xml php7.2-curl php7.2-bcmath
	rm -f /etc/nginx/sites-enabled/default;
	if (whiptail --title "Nginx Server Configuration" --yes-button "Primary" --no-button "Secondary"  --yesno "You are installing $answer as Default Server. If your answer is yes please select Primary, If you want to install as a secondary domain please select as Secondary" 10 60) then
		cat <<EOF > /etc/nginx/sites-available/$answer
		server {
		    listen 80 default_server;
		    listen [::]:80 default_server ipv6only=on;
			root /home/web/$answer/public;
			index index.php index.html index.htm;
			server_name localhost;
			charset   utf-8;
			gzip on;
			    gzip_vary on;
			    gzip_disable "msie6";
			    gzip_comp_level 6;
			    gzip_min_length 1100;
			    gzip_buffers 16 8k;
			    gzip_proxied any;
			    gzip_types
			        text/plain
			        text/css
			        text/js
			        text/xml
			        text/javascript
			        application/javascript
			        application/x-javascript
			        application/json
			        application/xml
			        application/xml+rss;
			location / {
			        try_files \$uri \$uri/ /index.php?\$query_string;
			    }
			location ~ \.php\$ {
			        try_files \$uri /index.php =404;
			        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
			        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
			        fastcgi_index index.php;
			        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
			        include fastcgi_params;
			    }
			location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc|svg|woff|woff2|ttf)\$ {
			      expires 1M;
			      access_log off;
			      add_header Cache-Control "public";
			    }
			location ~* \.(?:css|js)\$ {
			      expires 7d;
			      access_log off;
			      add_header Cache-Control "public";
			    }
			location ~ /\.ht {
			        deny  all;
			    }
			}
EOF
	else
		cat <<EOF > /etc/nginx/sites-available/$answer
		server {
		    listen 80;
		    listen [::]:80;
			root /home/web/$answer/public;
			index index.php index.html index.htm;
			server_name $answer;
			charset   utf-8;
			gzip on;
			    gzip_vary on;
			    gzip_disable "msie6";
			    gzip_comp_level 6;
			    gzip_min_length 1100;
			    gzip_buffers 16 8k;
			    gzip_proxied any;
			    gzip_types
			        text/plain
			        text/css
			        text/js
			        text/xml
			        text/javascript
			        application/javascript
			        application/x-javascript
			        application/json
			        application/xml
			        application/xml+rss;
			location / {
			        try_files \$uri \$uri/ /index.php?\$query_string;
			    }
			location ~ \.php\$ {
			        try_files \$uri /index.php =404;
			        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
			        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
			        fastcgi_index index.php;
			        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
			        include fastcgi_params;
			    }
			location ~* \.(?:jpg|jpeg|gif|png|ico|cur|gz|svg|svgz|mp4|ogg|ogv|webm|htc|svg|woff|woff2|ttf)\$ {
			      expires 1M;
			      access_log off;
			      add_header Cache-Control "public";
			    }
			location ~* \.(?:css|js)\$ {
			      expires 7d;
			      access_log off;
			      add_header Cache-Control "public";
			    }
			location ~ /\.ht {
			        deny  all;
			    }
			}
EOF
	fi
	ln -s /etc/nginx/sites-available/$answer /etc/nginx/sites-enabled/$answer
	apt-get install composer -y
	mkdir /home/web
	mkdir /home/web/$answer
	/etc/init.d/nginx restart
	composer create-project laravel/laravel /home/web/$answer
	mv /home/web/$answer/.env.example /home/web/$answer/.env
	cd /home/web/$answer && php artisan key:generate
	chown -R www-data:www-data /home/web/$answer
	chmod -R 775 /home/web/$answer/storage
else
    echo No
fi

if whiptail --yesno "Do you want to enable https support for $answer?" 20 60 ;then
	echo -n "Please Type Your Email Address to receive alerts regarding let's encrypt https support=="
	read email
	add-apt-repository ppa:certbot/certbot -y
	apt-get update -y
	apt-get install python-certbot-nginx -y
	nginx -t && nginx -s reload
	sudo certbot --nginx -d $answer -d www.$answer --email $email  --agree-tos --redirect --non-interactive
else
    echo No
fi
echo "Installation Completed Successfully"
