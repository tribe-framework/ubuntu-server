slug=$( awk 'END { print }' /var/www/html/docker-tribe-slugs.txt )
vars=$( awk 'END { print }' /var/www/html/logs/$slug-tribe-init.txt )
tport=$( awk 'END { print }' /var/www/html/logs/$slug-tribe-port.txt )
jport=$( awk 'END { print }' /var/www/html/logs/$slug-junction-port.txt )

echo "server {" >> /etc/nginx/sites-available/$slug.junction.express
echo "    server_name  $slug.tribe.junction.express;" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "    listen 443 ssl;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    ssl_certificate    /var/www/html/ssl/junction_express.pem;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    ssl_certificate_key    /var/www/html/ssl/junction_express.key;" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "    location / {" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_pass http://localhost:$tport/;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header Host \$host;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Real-IP \$remote_addr;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Forwarded-Proto \$scheme;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    }" >> /etc/nginx/sites-available/$slug.junction.express
echo "}" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "server {" >> /etc/nginx/sites-available/$slug.junction.express
echo "    server_name  $slug.junction.express;" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "    listen 443 ssl;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    ssl_certificate    /var/www/html/ssl/junction_express.pem;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    ssl_certificate_key    /var/www/html/ssl/junction_express.key;" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "    location / {" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_pass http://localhost:$jport/;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header Host \$host;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Real-IP \$remote_addr;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/sites-available/$slug.junction.express
echo "        proxy_set_header X-Forwarded-Proto \$scheme;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    }" >> /etc/nginx/sites-available/$slug.junction.express
echo "}" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "server {" >> /etc/nginx/sites-available/$slug.junction.express
echo "    if (\$host = $slug.junction.express) {" >> /etc/nginx/sites-available/$slug.junction.express
echo "        return 301 https://$host$request_uri;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    }" >> /etc/nginx/sites-available/$slug.junction.express
echo "    listen 80;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    server_name  $slug.junction.express;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    return 404;" >> /etc/nginx/sites-available/$slug.junction.express
echo "}" >> /etc/nginx/sites-available/$slug.junction.express
echo "" >> /etc/nginx/sites-available/$slug.junction.express
echo "server {" >> /etc/nginx/sites-available/$slug.junction.express
echo "    if (\$host = $slug.tribe.junction.express) {" >> /etc/nginx/sites-available/$slug.junction.express
echo "        return 301 https://$host$request_uri;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    }" >> /etc/nginx/sites-available/$slug.junction.express
echo "    listen 80;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    server_name  $slug.tribe.junction.express;" >> /etc/nginx/sites-available/$slug.junction.express
echo "    return 404;" >> /etc/nginx/sites-available/$slug.junction.express
echo "}" >> /etc/nginx/sites-available/$slug.junction.express

ln -s /etc/nginx/sites-available/$slug.junction.express /etc/nginx/sites-enabled/$slug.junction.express;
nginx -s reload;

php /var/www/html/docker-tribe-setup.php "$vars"

#/usr/bin/certbot --agree-tos --no-eff-email --email tech@wildfire.world --nginx -d $slug.junction.express -d $slug.tribe.junction.express;
#nginx -s reload;

curl "https://tribe.junction.express/custom/cloudflare/dns/setup-progress.php?step=finished&slug=$slug" >/dev/null 2>&1